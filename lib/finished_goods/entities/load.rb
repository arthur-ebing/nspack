# frozen_string_literal: true

module FinishedGoodsApp
  class Load < Dry::Struct
    attribute :id, Types::Integer
    attribute :customer_party_role_id, Types::Integer
    attribute :consignee_party_role_id, Types::Integer
    attribute :billing_client_party_role_id, Types::Integer
    attribute :exporter_party_role_id, Types::Integer
    attribute :final_receiver_party_role_id, Types::Integer
    attribute :final_destination_id, Types::Integer
    attribute :depot_id, Types::Integer
    attribute :pol_voyage_port_id, Types::Integer
    attribute :pod_voyage_port_id, Types::Integer
    attribute :order_number, Types::String
    attribute :edi_file_name, Types::String
    attribute :customer_order_number, Types::String
    attribute :customer_reference, Types::String
    attribute :exporter_certificate_code, Types::String
    attribute :shipped_at, Types::DateTime
    attribute :shipped, Types::Bool
    attribute :allocated_at, Types::DateTime
    attribute :allocated, Types::Bool
    attribute :transfer_load, Types::Bool
    attribute? :active, Types::Bool
  end

  class LoadFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :customer_party_role_id, Types::Integer
    attribute :consignee_party_role_id, Types::Integer
    attribute :billing_client_party_role_id, Types::Integer
    attribute :exporter_party_role_id, Types::Integer
    attribute :final_receiver_party_role_id, Types::Integer
    attribute :final_destination_id, Types::Integer
    attribute :depot_id, Types::Integer
    attribute :pol_voyage_port_id, Types::Integer
    attribute :pod_voyage_port_id, Types::Integer
    attribute :order_number, Types::String
    attribute :edi_file_name, Types::String
    attribute :customer_order_number, Types::String
    attribute :customer_reference, Types::String
    attribute :exporter_certificate_code, Types::String
    attribute :shipped_at, Types::DateTime
    attribute :shipped, Types::Bool
    attribute :allocated_at, Types::DateTime
    attribute :allocated, Types::Bool
    attribute :transfer_load, Types::Bool
    attribute :voyage_type_id, Types::Integer
    attribute :vessel_id, Types::Integer
    attribute :voyage_number, Types::String
    attribute :voyage_code, Types::String
    attribute :year, Types::Integer
    attribute :pol_port_id, Types::Integer
    attribute :pod_port_id, Types::Integer
    attribute :shipping_line_party_role_id, Types::Integer
    attribute :shipper_party_role_id, Types::Integer
    attribute :booking_reference, Types::String
    attribute :memo_pad, Types::String
    attribute :vehicle_number, Types::String
    attribute :container_code, Types::String
    attribute? :active, Types::Bool
  end
end
