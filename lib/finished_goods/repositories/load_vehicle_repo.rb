# frozen_string_literal: true

module FinishedGoodsApp
  class LoadVehicleRepo < BaseRepo
    build_for_select :load_vehicles,
                     label: :vehicle_number,
                     value: :id,
                     order_by: :vehicle_number
    build_inactive_select :load_vehicles,
                          label: :vehicle_number,
                          value: :id,
                          order_by: :vehicle_number

    crud_calls_for :load_vehicles, name: :load_vehicle, wrapper: LoadVehicle

    def find_load_vehicle_from(load_id:)
      DB[:load_vehicles].where(load_id: load_id).get(:id)
    end
  end
end
