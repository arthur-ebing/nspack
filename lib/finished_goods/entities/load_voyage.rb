# frozen_string_literal: true

module FinishedGoodsApp
  class LoadVoyage < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :voyage_id, Types::Integer
    attribute :shipping_line_party_role_id, Types::Integer
    attribute :shipping_line, Types::String
    attribute :shipper_party_role_id, Types::Integer
    attribute :shipper, Types::String
    attribute :booking_reference, Types::String
    attribute :memo_pad, Types::String
    attribute? :active, Types::Bool
  end
end
