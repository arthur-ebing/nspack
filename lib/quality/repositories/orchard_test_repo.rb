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

    def find_orchard_test_type_flat(id)
      query = <<~SQL
        SELECT
            orchard_test_types.*,
            string_agg(DISTINCT target_market_groups.target_market_group_name, ', ') AS applicable_tm_groups,
            string_agg(DISTINCT cultivars.cultivar_name, ', ') AS applicable_cultivars,
            string_agg(DISTINCT commodity_groups.code, ', ') AS applicable_commodity_groups
        FROM
            orchard_test_types
            LEFT JOIN target_market_groups ON target_market_groups.id = ANY (orchard_test_types.applicable_tm_group_ids)
            LEFT JOIN cultivars ON cultivars.id = ANY (orchard_test_types.applicable_cultivar_ids)
            LEFT JOIN commodity_groups ON commodity_groups.id = ANY (orchard_test_types.applicable_commodity_group_ids)
        WHERE orchard_test_types.id = #{id}
        GROUP BY
            orchard_test_types.id
      SQL
      OrchardTestTypeFlat.new(DB[query].first)
    end

    def create_orchard_test_type(params)
      attrs = params.to_h
      attrs[:applicable_tm_group_ids] = array_for_db_col(attrs[:applicable_tm_group_ids]) if attrs.key?(:applicable_tm_group_ids)
      attrs[:applicable_cultivar_ids] = array_for_db_col(attrs[:applicable_cultivar_ids]) if attrs.key?(:applicable_cultivar_ids)
      attrs[:applicable_commodity_group_ids] = array_for_db_col(attrs[:applicable_commodity_group_ids]) if attrs.key?(:applicable_commodity_group_ids)

      DB[:orchard_test_types].insert(attrs)
    end

    def update_orchard_test_type(id, params)
      attrs = params.to_h
      attrs[:applicable_tm_group_ids] = array_for_db_col(attrs[:applicable_tm_group_ids]) if attrs.key?(:applicable_tm_group_ids)
      attrs[:applicable_cultivar_ids] = array_for_db_col(attrs[:applicable_cultivar_ids]) if attrs.key?(:applicable_cultivar_ids)
      attrs[:applicable_commodity_group_ids] = array_for_db_col(attrs[:applicable_commodity_group_ids]) if attrs.key?(:applicable_commodity_group_ids)

      DB[:orchard_test_types].where(id: id).update(attrs)
    end
  end
end
