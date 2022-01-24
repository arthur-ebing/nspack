# frozen_string_literal: true

module MasterfilesApp
  QaStandardTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qa_standard_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
