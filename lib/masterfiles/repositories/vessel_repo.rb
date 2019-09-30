# frozen_string_literal: true

module MasterfilesApp
  class VesselRepo < BaseRepo
    build_for_select :vessels,
                     label: :vessel_code,
                     value: :id,
                     order_by: :vessel_code
    build_inactive_select :vessels,
                          label: :vessel_code,
                          value: :id,
                          order_by: :vessel_code

    crud_calls_for :vessels, name: :vessel, wrapper: Vessel

    def find_vessel_flat(id)
      find_with_association(:vessels,
                            id,
                            parent_tables: [{ parent_table: :voyage_types, columns: [:voyage_type_code], flatten_columns: { voyage_type_code: :voyage_type_code } }],
                            wrapper: VesselFlat)
    end
  end
end
