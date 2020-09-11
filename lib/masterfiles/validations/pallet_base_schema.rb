# frozen_string_literal: true

module MasterfilesApp
  PalletBaseSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pallet_base_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:length).maybe(:integer)
    required(:width).maybe(:integer)
    required(:edi_in_pallet_base).maybe(Types::StrippedString)
    required(:edi_out_pallet_base).maybe(Types::StrippedString)
    required(:cartons_per_layer).maybe(:integer)
    required(:material_mass).maybe(:decimal)
  end
end
