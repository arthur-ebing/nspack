# frozen_string_literal: true

module MasterfilesApp
  MrlSampleTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:sample_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
