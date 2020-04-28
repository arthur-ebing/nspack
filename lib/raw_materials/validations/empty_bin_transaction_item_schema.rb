# frozen_string_literal: true

module RawMaterialsApp
  EmptyBinTransactionItemSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:empty_bin_transaction_id, :integer).filled(:int?)
    required(:rmt_container_material_owner_id, :integer).filled(:int?)
    required(:empty_bin_from_location_id, :integer).filled(:int?)
    required(:empty_bin_to_location_id, :integer).filled(:int?)
    required(:quantity_bins, :integer).filled(:int?)
  end
end
