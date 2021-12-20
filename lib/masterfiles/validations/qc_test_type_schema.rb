# frozen_string_literal: true

module MasterfilesApp
  QcTestTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_test_type_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
