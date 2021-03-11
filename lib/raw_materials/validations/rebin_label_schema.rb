# frozen_string_literal: true

module RawMaterialsApp
  RebinLabelSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qty_to_print).filled(:integer)
    required(:printer).filled(Types::StrippedString)
    required(:rebin_label).filled(Types::StrippedString)
  end
end
