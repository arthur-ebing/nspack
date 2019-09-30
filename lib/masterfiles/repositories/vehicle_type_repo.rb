# frozen_string_literal: true

module MasterfilesApp
  class VehicleTypeRepo < BaseRepo
    build_for_select :vehicle_types,
                     label: :vehicle_type_code,
                     value: :id,
                     order_by: :vehicle_type_code
    build_inactive_select :vehicle_types,
                          label: :vehicle_type_code,
                          value: :id,
                          order_by: :vehicle_type_code

    crud_calls_for :vehicle_types, name: :vehicle_type, wrapper: VehicleType
  end
end
