# frozen_string_literal: true

module MasterfilesApp
  VesselSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:vessel_type_id).filled(:integer)
    required(:vessel_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
