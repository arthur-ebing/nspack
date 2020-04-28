# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinTransaction < Dry::Struct
    attribute :id, Types::Integer
    attribute :asset_transaction_type_id, Types::Integer
    attribute :empty_bin_to_location_id, Types::Integer
    attribute :fruit_reception_delivery_id, Types::Integer
    attribute :business_process_id, Types::Integer
    attribute :quantity_bins, Types::Integer
    attribute :transaction_type_code, Types::String
    attribute :process, Types::String
    attribute :location_long_code, Types::String
    attribute :truck_registration_number, Types::String
    attribute :reference_number, Types::String
    attribute :created_by, Types::String
    attribute :is_adhoc, Types::Bool
  end
end
