# frozen_string_literal: true

module ProductionApp
  GrowerGradingRuleItemSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:grower_grading_rule_id).filled(:integer)
    required(:commodity_id).filled(:integer)
    required(:marketing_variety_id).filled(:integer)
    required(:inspection_type_id).maybe(:integer)
    required(:rmt_class_id).maybe(:integer)
    optional(:grade_id).maybe(:integer)
    optional(:std_fruit_size_count_id).maybe(:integer)
    optional(:fruit_actual_counts_for_pack_id).maybe(:integer)
    optional(:fruit_size_reference_id).maybe(:integer)
    optional(:rmt_size_id).maybe(:integer)
    required(:legacy_data).maybe(:hash)
    required(:changes).maybe(:hash)
    optional(:created_by).filled(Types::StrippedString)
    optional(:updated_by).maybe(Types::StrippedString)
  end
end
