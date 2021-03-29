# frozen_string_literal: true

module ProductionApp
  class WorkOrder < Dry::Struct
    attribute :id, Types::Integer
    attribute :marketing_order_id, Types::Integer
    attribute :carton_qty_required, Types::Decimal
    attribute :carton_qty_produced, Types::Decimal
    attribute :start_date, Types::Date
    attribute :end_date, Types::Date
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute? :active, Types::Bool
  end
end
