# frozen_string_literal: true

module MasterfilesApp
  TreatmentTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:treatment_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
