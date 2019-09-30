# frozen_string_literal: true

module MasterfilesApp
  class VesselTypeRepo < BaseRepo
    build_for_select :vessel_types,
                     label: :vessel_type_code,
                     value: :id,
                     order_by: :vessel_type_code
    build_inactive_select :vessel_types,
                          label: :vessel_type_code,
                          value: :id,
                          order_by: :vessel_type_code

    crud_calls_for :vessel_types, name: :vessel_type, wrapper: VesselType

    def find_vessel_type_flat(id)
      find_with_association(:vessel_types,
                            id,
                            parent_tables: [{ parent_table: :voyage_types, columns: [:voyage_type_code], flatten_columns: { voyage_type_code: :voyage_type_code } }],
                            wrapper: VesselTypeFlat)
    end
  end
end
