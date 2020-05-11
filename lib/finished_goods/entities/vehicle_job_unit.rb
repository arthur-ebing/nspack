# frozen_string_literal: true

module FinishedGoodsApp
  class VehicleJobUnit < Dry::Struct
    attribute :id, Types::Integer
    attribute :vehicle_job_id, Types::Integer
    attribute :stock_type_id, Types::Integer
    attribute :stock_item_id, Types::Integer
    attribute :loaded_at, Types::DateTime
    attribute :offloaded_at, Types::DateTime
  end
end
