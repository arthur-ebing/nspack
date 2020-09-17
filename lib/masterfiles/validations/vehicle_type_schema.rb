# frozen_string_literal: true

module MasterfilesApp
  VehicleTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:vehicle_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:has_container).maybe(:bool)
  end
end
