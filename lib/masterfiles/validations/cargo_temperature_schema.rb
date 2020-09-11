# frozen_string_literal: true

module MasterfilesApp
  CargoTemperatureSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:temperature_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:set_point_temperature).maybe(:decimal)
    required(:load_temperature).maybe(:decimal)
  end
end
