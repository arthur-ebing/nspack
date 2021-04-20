# frozen_string_literal: true

module RawMaterialsApp
  ReceiveBinAssetSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:bin_asset_from_location_id).filled(:integer)
    required(:bin_asset_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:fruit_reception_delivery_id).maybe(:integer)
    required(:truck_registration_number).maybe(Types::StrippedString)
    required(:reference_number).maybe(Types::StrippedString)
  end

  IssueBinAssetSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:bin_asset_from_location_id).filled(:integer)
    required(:bin_asset_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:truck_registration_number).maybe(Types::StrippedString)
    required(:reference_number).maybe(Types::StrippedString)
  end

  AdhocBinAssetSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:bin_asset_from_location_id).filled(:integer)
    required(:bin_asset_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:reference_number).maybe(Types::StrippedString)
    required(:is_adhoc).filled(:bool)
  end

  AdhocCreateBinAssetSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:bin_asset_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:reference_number).maybe(Types::StrippedString)
    required(:is_adhoc).filled(:bool)
    required(:create).filled(:bool)
  end

  AdhocDestroyBinAssetSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:bin_asset_from_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:reference_number).maybe(Types::StrippedString)
    required(:is_adhoc).filled(:bool)
    required(:destroy).filled(:bool)
  end
end
