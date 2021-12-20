# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRuleItem < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_rule_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :grade_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :inspection_type_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :legacy_data, Types::Hash
    attribute :changes, Types::Hash
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
  end

  class GrowerGradingRuleItemFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :grower_grading_rule_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :grade_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :inspection_type_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :legacy_data, Types::Hash
    attribute :changes, Types::Hash
    attribute :created_by, Types::String
    attribute :updated_by, Types::String
    attribute? :active, Types::Bool
    attribute :grading_rule, Types::String
    attribute :commodity_code, Types::String
    attribute :marketing_variety_code, Types::String
    attribute :grade_code, Types::String
    attribute :inspection_type_code, Types::String
    attribute :actual_count, Types::Integer
    attribute :size_count, Types::Integer
    attribute :size_reference, Types::String
    attribute :rmt_class_code, Types::String
    attribute :rmt_size_code, Types::String
    attribute :rule_item_code, Types::String
  end
end
