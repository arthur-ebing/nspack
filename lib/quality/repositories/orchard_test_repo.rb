# frozen_string_literal: true

module QualityApp
  class OrchardTestRepo < BaseRepo
    build_for_select :orchard_test_types,
                     label: :test_type_code,
                     value: :id,
                     order_by: :test_type_code
    build_inactive_select :orchard_test_types,
                          label: :test_type_code,
                          value: :id,
                          order_by: :test_type_code

    crud_calls_for :orchard_test_types, name: :orchard_test_type, wrapper: OrchardTestType

    build_for_select :orchard_test_results,
                     label: :description,
                     value: :id,
                     order_by: :description
    build_inactive_select :orchard_test_results,
                          label: :description,
                          value: :id,
                          order_by: :description

    crud_calls_for :orchard_test_results, name: :orchard_test_result, wrapper: OrchardTestResult

    build_for_select :orchard_set_results,
                     label: :description,
                     value: :id,
                     order_by: :description
    build_inactive_select :orchard_set_results,
                          label: :description,
                          value: :id,
                          order_by: :description

    crud_calls_for :orchard_set_results, name: :orchard_set_result, wrapper: OrchardSetResult

    def find_orchard_test_type_flat(id)
      query = <<~SQL
        SELECT
            orchard_test_types.*,
            string_agg(DISTINCT target_market_groups.target_market_group_name, ', ') AS applicable_tm_groups,
            string_agg(DISTINCT cultivars.cultivar_name, ', ') AS applicable_cultivars,
            string_agg(DISTINCT commodity_groups.code, ', ') AS applicable_commodity_groups
        FROM orchard_test_types
        LEFT JOIN target_market_groups ON target_market_groups.id = ANY (orchard_test_types.applicable_tm_group_ids)
        LEFT JOIN cultivars ON cultivars.id = ANY (orchard_test_types.applicable_cultivar_ids)
        LEFT JOIN commodity_groups ON commodity_groups.id = ANY (orchard_test_types.applicable_commodity_group_ids)
        WHERE orchard_test_types.id = #{id}
        GROUP BY orchard_test_types.id
      SQL
      OrchardTestTypeFlat.new(DB[query].first)
    end

    def find_orchard_test_result_flat(id)
      query = <<~SQL
        SELECT
            orchard_test_results.*,
            orchard_test_types.test_type_code AS orchard_test_type_code,
            orchards.orchard_code,
            pucs.puc_code,
            cultivars.cultivar_name AS cultivar_code
        FROM orchard_test_results
        JOIN orchard_test_types ON orchard_test_types.id = orchard_test_results.orchard_test_type_id
        LEFT JOIN cultivars ON cultivars.id = orchard_test_results.cultivar_id
        LEFT JOIN orchards ON orchards.id = orchard_test_results.orchard_id
        LEFT JOIN pucs ON pucs.id = orchard_test_results.puc_id
        WHERE orchard_test_results.id = #{id}

      SQL
      hash = DB[query].first
      return nil if hash.nil?

      hash[:api_result] = nil if hash[:api_result].nil_or_empty?
      hash[:classifications] = nil if hash[:classifications].nil_or_empty?
      OrchardTestResultFlat.new(hash)
    end

    def array_for_db_ids(params)
      return nil if params.nil?

      attrs = params.to_h
      attrs.each do |k, v|
        attrs[k] = array_for_db_col(v) if k.to_s.end_with?('_ids')
      end
      attrs
    end

    def create_orchard_test_type(params)
      DB[:orchard_test_types].insert(array_for_db_ids(params))
    end

    def update_orchard_test_type(id, params)
      attrs = params.to_h
      attrs[:applicable_tm_group_ids] = nil if attrs[:applies_to_all_markets]

      if attrs[:applies_to_all_cultivars]
        attrs[:applicable_cultivar_ids] = nil
        attrs[:applicable_commodity_group_ids] = nil
      end

      DB[:orchard_test_types].where(id: id).update(array_for_db_ids(attrs))
    end

    def update_orchard_test_result(id, params) # rubocop:disable Metrics/AbcSize
      attrs = params.to_h
      attrs.delete(:api_result) if attrs[:api_result].nil_or_empty?
      attrs.delete(:classifications) if attrs[:classifications].nil_or_empty?
      attrs[:api_result] = hash_for_jsonb_col(attrs[:api_result]) if attrs.key?(:api_result)
      attrs[:classifications] = hash_for_jsonb_col(attrs[:classifications]) if attrs.key?(:classifications)

      DB[:orchard_test_results].where(id: id).update(attrs)
    end

    def for_select_orchards(args = {}, active = true)
      ds = DB[:orchards]
      ds = ds.where(args)
      ds = ds.where(Sequel[:orchards][:active] => active)
      ds.select_map([:orchard_code, Sequel[:orchards][:id]])
    end

    def for_select_inactive_orchards(args)
      for_select_orchards(args, false)
    end
  end
end
