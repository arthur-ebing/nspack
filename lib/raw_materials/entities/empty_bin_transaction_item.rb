# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinTransactionItem < Dry::Struct
    attribute :id, Types::Integer
    attribute :empty_bin_transaction_id, Types::Integer
    attribute :rmt_container_material_owner_id, Types::Integer
    attribute :empty_bin_from_location_id, Types::Integer
    attribute :empty_bin_to_location_id, Types::Integer
    attribute :quantity_bins, Types::Integer
  end
end
