# frozen_string_literal: true

module FinishedGoodsApp
  class Load < Dry::Struct
    attribute :id, Types::Integer
    attribute :depot_location_id, Types::Integer
    attribute :customer_party_role_id, Types::Integer
    attribute :consignee_party_role_id, Types::Integer
    attribute :billing_client_party_role_id, Types::Integer
    attribute :exporter_party_role_id, Types::Integer
    attribute :final_receiver_party_role_id, Types::Integer
    attribute :final_destination_id, Types::Integer
    attribute :pol_voyage_port_id, Types::Integer
    attribute :pod_voyage_port_id, Types::Integer
    attribute :order_number, Types::String
    attribute :edi_file_name, Types::String
    attribute :customer_order_number, Types::String
    attribute :customer_reference, Types::String
    attribute :exporter_certificate_code, Types::String
    attribute :shipped_date, Types::DateTime
    attribute :shipped, Types::Bool
    attribute :transfer_load, Types::Bool
    attribute? :active, Types::Bool
  end
end
