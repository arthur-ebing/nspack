# frozen_string_literal: true

module FinishedGoodsApp
  class VehicleJob < Dry::Struct
    attribute :id, Types::Integer
    attribute :vehicle_number, Types::String
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :planned_location_to_id, Types::Integer
    attribute :business_process_id, Types::Integer
    attribute :stock_type_id, Types::Integer
    attribute :loaded_at, Types::DateTime
    attribute :offloaded_at, Types::DateTime
  end
end
