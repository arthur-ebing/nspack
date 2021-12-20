# frozen_string_literal: true

module ProductionApp
  GrowerGradingRebinSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:grower_grading_pool_id).filled(:integer)
    optional(:grower_grading_rule_item_id).maybe(:integer)
    required(:rmt_class_id).maybe(:integer)
    required(:rmt_size_id).maybe(:integer)
    required(:rebins_quantity).maybe(:integer)
    required(:gross_weight).maybe(:decimal)
    required(:nett_weight).maybe(:decimal)
    required(:pallet_rebin).maybe(:bool)
    optional(:completed).maybe(:bool)
    optional(:updated_by).maybe(Types::StrippedString)
    optional(:changes_made).maybe(:hash)
  end
end
