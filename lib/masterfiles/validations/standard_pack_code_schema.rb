# frozen_string_literal: true

module MasterfilesApp
  StandardPackCodeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:standard_pack_code, Types::StrippedString).filled(:str?)
    required(:material_mass, :decimal).maybe(:decimal?)
    required(:plant_resource_button_indicator, Types::StrippedString).maybe(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
  end
end
