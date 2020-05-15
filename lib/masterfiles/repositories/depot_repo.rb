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
  end
end
