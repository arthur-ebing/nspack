# frozen_string_literal: true

module RawMaterialsApp
  ReceiveEmptyBinSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:empty_bin_from_location_id).filled(:integer)
    required(:empty_bin_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:fruit_reception_delivery_id).maybe(:integer)
    required(:truck_registration_number).maybe(Types::StrippedString)
    required(:reference_number).maybe(Types::StrippedString)
  end

  IssueEmptyBinSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:empty_bin_from_location_id).filled(:integer)
    required(:empty_bin_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:truck_registration_number).maybe(Types::StrippedString)
    required(:reference_number).maybe(Types::StrippedString)
  end

  AdhocEmptyBinSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:empty_bin_from_location_id).filled(:integer)
    required(:empty_bin_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:reference_number).maybe(Types::StrippedString)
    required(:is_adhoc).filled(:bool)
  end

  AdhocCreateEmptyBinSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:empty_bin_to_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:reference_number).maybe(Types::StrippedString)
    required(:is_adhoc).filled(:bool)
    required(:create).filled(:bool)
  end

  AdhocDestroyEmptyBinSchema = Dry::Schema.Params do
    required(:asset_transaction_type_id).filled(:integer)
    required(:empty_bin_from_location_id).filled(:integer)
    required(:business_process_id).filled(:integer)
    required(:quantity_bins).filled(:integer, gt?: 0)
    required(:reference_number).maybe(Types::StrippedString)
    required(:is_adhoc).filled(:bool)
    required(:destroy).filled(:bool)
  end
end
