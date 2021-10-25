# frozen_string_literal: true

module MasterfilesApp
  class DepotRepo < BaseRepo
    build_for_select :depots,
                     label: :depot_code,
                     value: :id,
                     order_by: :depot_code
    build_inactive_select :depots,
                          label: :depot_code,
                          value: :id,
                          order_by: :depot_code

    crud_calls_for :depots, name: :depot, wrapper: Depot

    def find_depot_flat(id)
      find_with_association(:depots,
                            id,
                            parent_tables: [{ parent_table: :destination_cities,
                                              columns: %i[city_name],
                                              foreign_key: :city_id,
                                              flatten_columns: { city_name: :city_name } }],
                            wrapper: DepotFlat)
    end

    def create_depot_location(params)
      attrs = { primary_storage_type_id: get_id(:location_storage_types, storage_type_code: AppConst::STORAGE_TYPE_BIN_ASSET),
                location_type_id: get_id(:location_types, location_type_code: AppConst::DEPOT_DESTINATION_TYPE),
                primary_assignment_id: get_id(:location_assignments, assignment_code: AppConst::EMPTY_BIN_STORAGE),
                location_long_code: params[:depot_code],
                location_description: params[:depot_code],
                location_short_code: params[:depot_code] }
      DB[:locations].insert(attrs)
    end
  end
end
