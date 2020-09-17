# frozen_string_literal: true

module MasterfilesApp
  VesselTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:voyage_type_id).filled(:integer)
    required(:vessel_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
