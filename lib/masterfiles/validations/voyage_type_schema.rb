# frozen_string_literal: true

module MasterfilesApp
  VoyageTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:voyage_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
