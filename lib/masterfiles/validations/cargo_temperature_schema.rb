# frozen_string_literal: true

module MasterfilesApp
  CargoTemperatureSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:temperature_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:set_point_temperature, %i[nil decimal]).maybe(:decimal?)
    required(:load_temperature, %i[nil decimal]).maybe(:decimal?)
  end
end
