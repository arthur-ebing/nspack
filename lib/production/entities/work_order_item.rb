# frozen_string_literal: true

module ProductionApp
  class WorkOrderItem < Dry::Struct
    attribute :id, Types::Integer
    attribute :work_order_id, Types::Integer
    attribute :product_setup_id, Types::Integer
    attribute :carton_qty_required, Types::Decimal
    attribute :carton_qty_produced, Types::Decimal
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
  end
end
