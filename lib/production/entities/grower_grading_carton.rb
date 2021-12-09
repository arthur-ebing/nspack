# frozen_string_literal: true

module ProductionApp
  class GrowerGradingCarton < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_pool_id, Types::Integer
    attribute :grower_grading_rule_item_id, Types::Integer
    attribute :product_resource_allocation_id, Types::Integer
    attribute :pm_bom_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :grade_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :changes_made, Types::Hash
    attribute :carton_quantity, Types::Integer
    attribute :inspected_quantity, Types::Integer
    attribute :not_inspected_quantity, Types::Integer
    attribute :failed_quantity, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute :completed, Types::Bool
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
  end

  class GrowerGradingCartonFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_pool_id, Types::Integer
    attribute :grower_grading_rule_item_id, Types::Integer
    attribute :product_resource_allocation_id, Types::Integer
    attribute :pm_bom_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :grade_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :changes_made, Types::Hash
    attribute :carton_quantity, Types::Integer
    attribute :inspected_quantity, Types::Integer
    attribute :not_inspected_quantity, Types::Integer
    attribute :failed_quantity, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute :completed, Types::Bool
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
    attribute :pool_name, Types::String
    attribute :grading_carton_code, Types::String
    attribute :bom_code, Types::String
    attribute :actual_count, Types::Integer
    attribute :size_count, Types::Integer
    attribute :marketing_org, Types::String
    attribute :packed_tm_group, Types::String
    attribute :target_market, Types::String
    attribute :inventory_code, Types::String
    attribute :rmt_class_code, Types::String
    attribute :grade_code, Types::String
    attribute :marketing_variety_code, Types::String
    attribute :size_reference, Types::String
  end
end
