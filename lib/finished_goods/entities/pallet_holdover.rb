# frozen_string_literal: true

module FinishedGoodsApp
  class PalletHoldover < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :holdover_quantity, Types::Integer
    attribute :buildup_remarks, Types::String
    attribute :completed, Types::Bool
  end
end
