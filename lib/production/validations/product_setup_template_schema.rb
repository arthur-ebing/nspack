# frozen_string_literal: true

module ProductionApp
  ProductSetupTemplateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:template_name, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:cultivar_group_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).maybe(:int?)
    required(:packhouse_resource_id, :integer).maybe(:int?)
    required(:production_line_resource_id, :integer).maybe(:int?)
    required(:season_group_id, :integer).maybe(:int?)
    required(:season_id, :integer).maybe(:int?)
    required(:active, :bool).maybe(:bool?)
  end
end
