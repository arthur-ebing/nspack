# frozen_string_literal: true

module MasterfilesApp
  InspectionFailureTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:failure_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
