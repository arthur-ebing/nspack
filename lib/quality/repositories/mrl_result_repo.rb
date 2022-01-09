# frozen_string_literal: true

module QualityApp
  class MrlResultRepo < BaseRepo
    build_for_select :mrl_results,
                     label: :waybill_number,
                     value: :id,
                     order_by: :waybill_number
    build_inactive_select :mrl_results,
                          label: :waybill_number,
                          value: :id,
                          order_by: :waybill_number

    crud_calls_for :mrl_results, name: :mrl_result, wrapper: MrlResult

    def find_mrl_result(id)
      find_with_association(:mrl_results,
                            id,
                            parent_tables: [{ parent_table: :cultivars,
                                              columns: [:cultivar_name],
                                              flatten_columns: { cultivar_name: :cultivar_name } },
                                            { parent_table: :pucs,
                                              columns: [:puc_code],
                                              flatten_columns: { puc_code: :puc_code } },
                                            { parent_table: :seasons,
                                              columns: [:season_code],
                                              flatten_columns: { season_code: :season_code } },
                                            { parent_table: :farms,
                                              columns: [:farm_code],
                                              flatten_columns: { farm_code: :farm_code } },
                                            { parent_table: :orchards,
                                              columns: [:orchard_code],
                                              flatten_columns: { orchard_code: :orchard_code } },
                                            { parent_table: :laboratories,
                                              columns: [:lab_code],
                                              flatten_columns: { lab_code: :lab_code } },
                                            { parent_table: :mrl_sample_types,
                                              columns: [:sample_type_code],
                                              flatten_columns: { sample_type_code: :sample_type_code } }],
                            lookup_functions: [{ function: :fn_production_run_code,
                                                 args: [:id],
                                                 col_name: :production_run_code }],
                            wrapper: MrlResultFlat)
    end

    def for_select_rmt_deliveries(where: {}) # rubocop:disable Metrics/AbcSize
      DB[:rmt_deliveries]
        .join(:farms, id: :farm_id)
        .join(:orchards, id: Sequel[:rmt_deliveries][:orchard_id])
        .where(convert_empty_values(where))
        .select(:farm_code, :orchard_code, :date_delivered, Sequel[:rmt_deliveries][:id])
        .map { |r| ["#{r[:farm_code]}_#{r[:orchard_code]}_#{r[:date_delivered].strftime('%d/%m/%Y')} (#{r[:id]})", r[:id]] }.uniq
    end

    def look_for_existing_mrl_result_id(args)
      id = get_id(:mrl_results, args)
      id
    end

    def mrl_result_data(attrs) # rubocop:disable Metrics/AbcSize
      arr = %i[ waybill_number reference_number sample_number ph_level num_active_ingredients
                pre_harvest_result post_harvest_result fruit_received_at sample_submitted_at]
      defaults = attrs.to_h.slice(*arr)
      defaults[:season_code] = get(:seasons, attrs[:season_id], :season_code)
      defaults[:lab_code] = get(:laboratories, attrs[:laboratory_id], :lab_code)
      defaults[:sample_type_code] = get(:mrl_sample_types, attrs[:mrl_sample_type_id], :sample_type_code)

      args = if attrs[:pre_harvest_result]
               { rmt_delivery_id: attrs[:rmt_delivery_id],
                 cultivar_name: get(:cultivars, attrs[:cultivar_id], :cultivar_name),
                 puc_code: get(:pucs, attrs[:puc_id], :puc_code),
                 farm_code: get(:farms, attrs[:farm_id], :farm_code),
                 orchard_code: get(:orchards, attrs[:orchard_id], :orchard_code) }
             else
               { production_run_code: DB.get(Sequel.function(:fn_production_run_code, attrs[:production_run_id])) }
             end
      defaults.merge(args)
    end

    def mrl_result_attrs_for(delivery_id, arr)
      attrs = where_hash(:rmt_deliveries, id: delivery_id) || {}
      attrs = attrs.slice(*arr)
      attrs[:pre_harvest_result] = true
      attrs
    end

    def find_mrl_result_label_data(mrl_result_id)
      query = <<~SQL
        SELECT mrl_results.id AS mrl_result_id,
               mrl_results.rmt_delivery_id,
               mrl_results.reference_number,
               rmt_deliveries.reference_number AS delivery_ref_no,
               mrl_results.cultivar_id,
               mrl_results.farm_id,
               mrl_results.puc_id,
               mrl_results.orchard_id,
               cultivars.cultivar_name,
               pucs.puc_code,
               farms.farm_code,
               orchards.orchard_code,
               mrl_results.fruit_received_at,
               mrl_results.sample_submitted_at,
               mrl_results.laboratory_id,
               mrl_results.mrl_sample_type_id,
               laboratories.lab_code,
               mrl_sample_types.sample_type_code,
               rmt_deliveries.rmt_code_id,
               rmt_codes.rmt_code
        FROM mrl_results
        LEFT JOIN rmt_deliveries ON rmt_deliveries.id = mrl_results.rmt_delivery_id
        LEFT JOIN cultivars ON cultivars.id = mrl_results.cultivar_id
        LEFT JOIN farms ON farms.id = mrl_results.farm_id
        LEFT JOIN orchards ON orchards.id = mrl_results.orchard_id
        LEFT JOIN pucs ON pucs.id = mrl_results.puc_id
        JOIN laboratories ON laboratories.id = mrl_results.laboratory_id
        JOIN mrl_sample_types ON mrl_sample_types.id = mrl_results.mrl_sample_type_id
        LEFT JOIN rmt_codes ON rmt_codes.id = rmt_deliveries.rmt_code_id
        WHERE mrl_results.id = ?
      SQL
      DB[query, mrl_result_id].first unless mrl_result_id.nil?
    end

    def check_mrl_results_status(mrl_result_ids, where: {}, exclude: {})
      !DB[:mrl_results]
        .where(id: mrl_result_ids)
        .where(where)
        .exclude(exclude)
        .empty?
    end

    def mrl_result_summary(mrl_result_id)
      return [] if mrl_result_id.nil?

      query = <<~SQL
        SELECT mrl_sample_types.sample_type_code,
               laboratories.lab_code,
               mrl_results.sample_number,
               mrl_results.reference_number,
               mrl_results.mrl_sample_passed,
               mrl_results.max_num_chemicals_passed,
               mrl_results.result_received_at
        FROM mrl_results
        JOIN laboratories ON laboratories.id = mrl_results.laboratory_id
        JOIN mrl_sample_types ON mrl_sample_types.id = mrl_results.mrl_sample_type_id
        WHERE mrl_results.id = ?
      SQL
      DB[query, mrl_result_id].all
    end
  end
end
