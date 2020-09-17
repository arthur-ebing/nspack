# frozen_string_literal: true

module MasterfilesApp
  FruitSizeReferenceSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:size_reference).filled(Types::StrippedString)
    required(:edi_out_code).maybe(Types::StrippedString)
  end
end
