# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryCost < Dry::Struct
    attribute :rmt_delivery_id, Types::Integer
    attribute :cost_id, Types::Integer
    attribute :amount, Types::Decimal
    attribute :description, Types::StrippedString
  end
end
