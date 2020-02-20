# frozen_string_literal: true

module ProductionApp
  class ShiftException < Dry::Struct
    attribute :id, Types::Integer
    attribute :shift_id, Types::Integer
    attribute :contract_worker_id, Types::Integer
    attribute :contract_worker_name, Types::String
    attribute :remarks, Types::String
    attribute :running_hours, Types::Decimal
  end
end
