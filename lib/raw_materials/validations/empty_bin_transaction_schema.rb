# frozen_string_literal: true

module RawMaterialsApp
  ReceiveEmptyBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:asset_transaction_type_id, :integer).filled(:int?)
    required(:empty_bin_from_location_id, :integer).filled(:int?)
    required(:empty_bin_to_location_id, :integer).filled(:int?)
    required(:business_process_id, :integer).filled(:int?)
    required(:quantity_bins, :integer).filled(:int?)
    required(:fruit_reception_delivery_id, :integer).filled(:int?)
    required(:truck_registration_number, Types::StrippedString).maybe(:str?)
    required(:reference_number, Types::StrippedString).filled(:str?)
  end

  IssueEmptyBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:asset_transaction_type_id, :integer).filled(:int?)
    required(:empty_bin_from_location_id, :integer).filled(:int?)
    required(:empty_bin_to_location_id, :integer).filled(:int?)
    required(:business_process_id, :integer).filled(:int?)
    required(:quantity_bins, :integer).filled(:int?)
    required(:truck_registration_number, Types::StrippedString).maybe(:str?)
    required(:reference_number, Types::StrippedString).filled(:str?)
  end

  AdhocEmptyBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:asset_transaction_type_id, :integer).filled(:int?)
    required(:empty_bin_from_location_id, :integer).filled(:int?)
    required(:empty_bin_to_location_id, :integer).filled(:int?)
    required(:business_process_id, :integer).filled(:int?)
    required(:quantity_bins, :integer).filled(:int?)
    required(:reference_number, Types::StrippedString).filled(:str?)
    required(:is_adhoc, :bool).filled(:bool?)
  end
end
