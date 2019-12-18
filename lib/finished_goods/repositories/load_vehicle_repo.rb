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

    def find_load_vehicle_flat(id)
      find_with_association(:load_vehicles,
                            id,
                            parent_tables: [{ parent_table: :vehicle_types,
                                              columns: %i[vehicle_type_code],
                                              foreign_key: :vehicle_type_id,
                                              flatten_columns: { vehicle_type_code: :vehicle_type_code } }],
                            lookup_functions: [{ function: :fn_party_role_name,
                                                 args: [:haulier_party_role_id],
                                                 col_name: :haulier_party_role }],
                            wrapper: LoadVehicleFlat)
    end

    def find_load_vehicle_from(load_id:)
      DB[:load_vehicles].where(load_id: load_id).get(:id)
    end
  end
end
