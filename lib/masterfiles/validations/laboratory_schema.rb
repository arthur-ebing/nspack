# frozen_string_literal: true

module MasterfilesApp
  LaboratorySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:lab_code).filled(Types::StrippedString)
    required(:lab_name).maybe(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
