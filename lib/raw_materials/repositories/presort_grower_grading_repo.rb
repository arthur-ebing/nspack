# frozen_string_literal: true

module RawMaterialsApp
  class PresortGrowerGradingRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :presort_grower_grading_pools,
                     label: :maf_lot_number,
                     value: :id,
                     order_by: :maf_lot_number
    build_inactive_select :presort_grower_grading_pools,
                          label: :maf_lot_number,
                          value: :id,
                          order_by: :maf_lot_number

    build_for_select :presort_grower_grading_bins,
                     label: :maf_rmt_code,
                     value: :id,
                     order_by: :maf_rmt_code
    build_inactive_select :presort_grower_grading_bins,
                          label: :maf_rmt_code,
                          value: :id,
                          order_by: :maf_rmt_code

    crud_calls_for :presort_grower_grading_pools, name: :presort_grower_grading_pool, wrapper: PresortGrowerGradingPool
    crud_calls_for :presort_grower_grading_bins, name: :presort_grower_grading_bin, wrapper: PresortGrowerGradingBin

    def find_presort_grower_grading_pool(id)
      hash = find_with_association(:presort_grower_grading_pools,
                                   id,
                                   parent_tables: [{ parent_table: :commodities,
                                                     columns: [:code],
                                                     flatten_columns: { code: :commodity_code } },
                                                   { parent_table: :seasons,
                                                     columns: [:season_code],
                                                     flatten_columns: { season_code: :season_code } },
                                                   { parent_table: :farms,
                                                     columns: [:farm_code],
                                                     flatten_columns: { farm_code: :farm_code } }])
      return nil if hash.nil?

      hash[:total_graded_weight] = select_values(:presort_grower_grading_bins, :rmt_bin_weight, presort_grower_grading_pool_id: id).sum
      PresortGrowerGradingPoolFlat.new(hash)
    end

    def find_presort_grower_grading_bin(id)
      hash = find_with_association(:presort_grower_grading_bins,
                                   id,
                                   parent_tables: [{ parent_table: :presort_grower_grading_pools,
                                                     columns: [:maf_lot_number],
                                                     flatten_columns: { maf_lot_number: :maf_lot_number } },
                                                   { parent_table: :farms,
                                                     columns: [:farm_code],
                                                     flatten_columns: { farm_code: :farm_code } },
                                                   { parent_table: :rmt_classes,
                                                     columns: [:rmt_class_code],
                                                     flatten_columns: { rmt_class_code: :rmt_class_code } },
                                                   { parent_table: :rmt_sizes,
                                                     columns: [:size_code],
                                                     flatten_columns: { size_code: :rmt_size_code } },
                                                   { parent_table: :treatments,
                                                     columns: [:treatment_code],
                                                     flatten_columns: { treatment_code: :colour } }])
      return nil if hash.nil?

      hash[:adjusted_weight] = hash[:maf_weight] - hash[:rmt_bin_weight]
      PresortGrowerGradingBinFlat.new(hash)
    end

    def delete_presort_grower_grading_pool(id)
      DB[:presort_grower_grading_bins].where(presort_grower_grading_pool_id: id).delete
      DB[:presort_grower_grading_pools].where(id: id).delete
      { success: true }
    end

    def delete_presort_grower_bins_for(grading_pool_id)
      DB[:presort_grower_grading_bins].where(presort_grower_grading_pool_id: grading_pool_id).delete
      { success: true }
    end

    def presort_grower_grading_bin_ids(presort_grower_grading_pool_id)
      DB[:presort_grower_grading_bins].where(presort_grower_grading_pool_id: presort_grower_grading_pool_id).select_map(:id)
    end

    def maf_lot_number_exists?(maf_lot_number)
      exists?(:rmt_bins, presort_tip_lot_number: maf_lot_number)
    end

    def grading_pool_exists?(maf_lot_number)
      exists?(:presort_grower_grading_pools, maf_lot_number: maf_lot_number)
    end

    def grading_pool_bins_exists?(maf_lot_number)
      exists?(:rmt_bins, presort_tip_lot_number: maf_lot_number, active: true, scrapped: false, bin_tipped: true)
    end

    def presort_grading_pool_details_for(maf_lot_number)
      query = <<~SQL
        SELECT rmt_bins.presort_tip_lot_number AS maf_lot_number,
               rmt_bins.legacy_data ->> 'track_indicator_code' AS track_slms_indicator_code,
               rmt_bins.season_id,
               seasons.commodity_id,
               rmt_bins.farm_id,
               SUM(rmt_bins.qty_bins) AS rmt_bin_count,
               SUM(rmt_bins.nett_weight) AS rmt_bin_weight
        FROM rmt_bins
        JOIN seasons on rmt_bins.season_id = seasons.id
        WHERE rmt_bins.presort_tip_lot_number = ?
        AND rmt_bins.active
        AND rmt_bins.bin_tipped
        AND NOT rmt_bins.scrapped
        GROUP BY rmt_bins.presort_tip_lot_number, track_slms_indicator_code,
                 rmt_bins.season_id, seasons.commodity_id, rmt_bins.farm_id
      SQL
      DB[query, maf_lot_number].all unless maf_lot_number.nil?
    end

    def presort_grading_pool_farm_for(presort_grading_pool_id)
      DB[:presort_grower_grading_pools]
        .join(:farms, id: :farm_id)
        .where(Sequel[:presort_grower_grading_pools][:id] => presort_grading_pool_id)
        .get(%i[farm_id farm_code])
    end

    def look_for_existing_grading_bin_id(res)
      args = res.to_h.reject { |k, _| %i[id active graded maf_weight rmt_bin_weight created_by updated_by created_at updated_at].include?(k) }
      id = get_id(:presort_grower_grading_bins, args)
      id
    end
  end
end
