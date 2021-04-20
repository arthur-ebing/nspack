# frozen_string_literal: true

module RawMaterialsApp
  class BinAssetTransactionItem < Dry::Struct
    attribute :id, Types::Integer
    attribute :bin_asset_transaction_id, Types::Integer
    attribute :rmt_container_material_owner_id, Types::Integer
    attribute :bin_asset_from_location_id, Types::Integer
    attribute :bin_asset_to_location_id, Types::Integer
    attribute :quantity_bins, Types::Integer
  end
end
