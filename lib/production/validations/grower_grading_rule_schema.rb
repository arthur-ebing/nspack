# frozen_string_literal: true

module ProductionApp
  GrowerGradingRuleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rule_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    optional(:file_name).maybe(Types::StrippedString)
    required(:packhouse_resource_id).maybe(:integer)
    required(:line_resource_id).maybe(:integer)
    required(:season_id).maybe(:integer)
    required(:cultivar_group_id).filled(:integer)
    required(:cultivar_id).maybe(:integer)
    required(:rebin_rule).maybe(:bool)
    required(:created_by).filled(Types::StrippedString)
    optional(:updated_by).maybe(Types::StrippedString)
  end
end
