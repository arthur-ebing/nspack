# frozen_string_literal: true

module MasterfilesApp
  TreatmentSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:treatment_type_id).filled(:integer)
    required(:treatment_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
