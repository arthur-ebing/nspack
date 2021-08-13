# frozen_string_literal: true

module FinishedGoodsApp
  class PalletBuildup < Dry::Struct
    attribute :id, Types::Integer
    attribute :destination_pallet_number, Types::String
    attribute :source_pallets, Types::Array
    attribute :qty_cartons_to_move, Types::Integer
    attribute :created_by, Types::String
    attribute :completed_at, Types::DateTime
    attribute :created_at, Types::DateTime
    attribute :cartons_moved, Types::Hash
    attribute :completed, Types::Bool
    attribute :auto_create_destination_pallet, Types::Bool
  end
end
