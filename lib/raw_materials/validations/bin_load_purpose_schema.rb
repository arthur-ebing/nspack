# frozen_string_literal: true

module RawMaterialsApp
  BinLoadPurposeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:purpose_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
