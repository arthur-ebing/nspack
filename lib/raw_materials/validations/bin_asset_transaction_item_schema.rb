# frozen_string_literal: true

module RawMaterialsApp
  BinAssetTransactionItemSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:bin_asset_transaction_id).filled(:integer)
    required(:rmt_container_material_owner_id).filled(:integer)
    required(:bin_asset_from_location_id).filled(:integer)
    required(:bin_asset_to_location_id).filled(:integer)
    required(:quantity_bins).filled(:integer)
  end
end
