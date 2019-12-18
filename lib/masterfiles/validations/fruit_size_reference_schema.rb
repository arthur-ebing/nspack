# frozen_string_literal: true

module MasterfilesApp
  FruitSizeReferenceSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:size_reference, Types::StrippedString).filled(:str?)
    required(:edi_out_code, Types::StrippedString).maybe(:str?)
  end
end
