# frozen_string_literal: true

module ProductionApp
  GrowerGradingCartonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:grower_grading_pool_id).filled(:integer)
    optional(:grower_grading_rule_item_id).maybe(:integer)
    optional(:product_resource_allocation_id).maybe(:integer)
    required(:pm_bom_id).maybe(:integer)
    required(:std_fruit_size_count_id).maybe(:integer)
    required(:fruit_actual_counts_for_pack_id).maybe(:integer)
    required(:marketing_org_party_role_id).filled(:integer)
    required(:packed_tm_group_id).filled(:integer)
    required(:target_market_id).maybe(:integer)
    required(:inventory_code_id).maybe(:integer)
    required(:rmt_class_id).maybe(:integer)
    required(:grade_id).filled(:integer)
    required(:marketing_variety_id).filled(:integer)
    required(:fruit_size_reference_id).maybe(:integer)
    required(:carton_quantity).maybe(:integer)
    required(:inspected_quantity).maybe(:integer)
    required(:not_inspected_quantity).maybe(:integer)
    required(:failed_quantity).maybe(:integer)
    required(:gross_weight).maybe(:decimal)
    required(:nett_weight).maybe(:decimal)
    optional(:completed).maybe(:bool)
    optional(:updated_by).maybe(Types::StrippedString)
    optional(:changes_made).maybe(:hash)
  end
end
