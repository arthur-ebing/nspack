# frozen_string_literal: true

module FinishedGoodsApp
  class VoyagePort < Dry::Struct
    attribute :id, Types::Integer
    attribute :voyage_id, Types::Integer
    attribute :port_id, Types::Integer
    attribute :trans_shipment_vessel_id, Types::Integer
    attribute :ata, Types::DateTime
    attribute :atd, Types::DateTime
    attribute :eta, Types::DateTime
    attribute :etd, Types::DateTime
    attribute? :active, Types::Bool
  end

  class VoyagePortFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :voyage_id, Types::Integer
    attribute :port_id, Types::Integer
    attribute :trans_shipment_vessel_id, Types::Integer
    attribute :ata, Types::DateTime
    attribute :atd, Types::DateTime
    attribute :eta, Types::DateTime
    attribute :etd, Types::DateTime
    attribute :trans_shipment_vessel, Types::String
    attribute :port_code, Types::String
    attribute :port_type_id, Types::Integer
    attribute :port_type_code, Types::String
    attribute? :active, Types::Bool
  end
end
