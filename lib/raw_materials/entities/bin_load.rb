# frozen_string_literal: true

module RawMaterialsApp
  class BinLoad < Dry::Struct
    attribute :id, Types::Integer
    attribute :bin_load_purpose_id, Types::Integer
    attribute :customer_party_role_id, Types::Integer
    attribute :transporter_party_role_id, Types::Integer
    attribute :dest_depot_id, Types::Integer
    attribute :qty_bins, Types::Integer
    attribute :shipped_at, Types::DateTime
    attribute :shipped, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :completed, Types::Bool
    attribute? :active, Types::Bool
  end
  class BinLoadFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :bin_load_purpose_id, Types::Integer
    attribute :customer_party_role_id, Types::Integer
    attribute :transporter_party_role_id, Types::Integer
    attribute :dest_depot_id, Types::Integer
    attribute :qty_bins, Types::Integer
    attribute :shipped_at, Types::DateTime
    attribute :shipped, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :completed, Types::Bool
    attribute? :active, Types::Bool
    attribute :purpose_code, Types::String
    attribute :customer, Types::String
    attribute :transporter, Types::String
    attribute :dest_depot, Types::String
    attribute :products, Types::Bool
    attribute :qty_product_bins, Types::Integer
    attribute :available_bin_ids, Types::Array
    attribute :qty_bins_available, Types::Integer
  end
end
