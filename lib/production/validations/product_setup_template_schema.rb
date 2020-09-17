# frozen_string_literal: true

module ProductionApp
  ProductSetupTemplateSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:template_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:cultivar_group_id).filled(:integer)
    required(:cultivar_id).maybe(:integer)
    required(:packhouse_resource_id).maybe(:integer)
    required(:production_line_id).maybe(:integer)
    required(:season_group_id).maybe(:integer)
    required(:season_id).maybe(:integer)
    # required(:active).maybe(:bool)
  end
end
