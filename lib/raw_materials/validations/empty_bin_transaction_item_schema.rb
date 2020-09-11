# frozen_string_literal: true

module RawMaterialsApp
  EmptyBinTransactionItemSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:empty_bin_transaction_id).filled(:integer)
    required(:rmt_container_material_owner_id).filled(:integer)
    required(:empty_bin_from_location_id).filled(:integer)
    required(:empty_bin_to_location_id).filled(:integer)
    required(:quantity_bins).filled(:integer)
  end
end
