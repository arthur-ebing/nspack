# frozen_string_literal: true

module MasterfilesApp
  CartonsPerPalletSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:description).maybe(Types::StrippedString)
    required(:pallet_format_id).filled(:integer)
    required(:basic_pack_id).filled(:integer)
    required(:cartons_per_pallet).filled(:integer)
    required(:layers_per_pallet).filled(:integer)
  end
end
