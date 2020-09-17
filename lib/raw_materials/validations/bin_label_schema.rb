# frozen_string_literal: true

module RawMaterialsApp
  BinLabelSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    # required(:orchard_id).filled(:integer)
    # required(:cultivar_id).filled(:integer)
    # required(:farm_id).filled(:integer)
    # required(:puc_id).filled(:integer)
    required(:printer).filled(Types::StrippedString)
    required(:bin_label).filled(Types::StrippedString)
  end
end
