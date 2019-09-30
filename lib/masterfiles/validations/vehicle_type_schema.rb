# frozen_string_literal: true

module MasterfilesApp
  VehicleTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:vehicle_type_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:has_container, :bool).maybe(:bool?)
  end
end
