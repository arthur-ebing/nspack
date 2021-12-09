# frozen_string_literal: true

module ProductionApp
  NewGrowerGradingPoolSchema = Dry::Schema.Params do
    required(:pool_name).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    required(:production_run_id).filled(:integer)
    optional(:inspection_type_id).maybe(:integer)
    optional(:updated_by).maybe(Types::StrippedString)
  end

  EditGrowerGradingPoolSchema = Dry::Schema.Params do
    required(:pool_name).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    optional(:inspection_type_id).maybe(:integer)
    required(:updated_by).maybe(Types::StrippedString)
  end

  GrowerGradingPoolSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:grower_grading_rule_id).maybe(:integer)
    required(:pool_name).filled(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
    required(:production_run_id).maybe(:integer)
    required(:season_id).maybe(:integer)
    required(:cultivar_group_id).filled(:integer)
    required(:cultivar_id).maybe(:integer)
    required(:commodity_id).filled(:integer)
    required(:farm_id).filled(:integer)
    optional(:inspection_type_id).maybe(:integer)
    required(:bin_quantity).maybe(:integer)
    required(:gross_weight).maybe(:decimal)
    required(:nett_weight).maybe(:decimal)
    optional(:pro_rata_factor).maybe(:decimal)
    required(:legacy_data).maybe(:hash)
    optional(:completed).maybe(:bool)
    optional(:rule_applied).maybe(:bool)
    required(:created_by).maybe(Types::StrippedString)
    optional(:updated_by).maybe(Types::StrippedString)
    optional(:rule_applied_by).maybe(Types::StrippedString)
    optional(:rule_applied_at).maybe(:time)
  end
end
