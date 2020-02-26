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
                            parent_tables: [{ parent_table: :vessel_types,
                                              columns: %i[vessel_type_code voyage_type_id],
                                              flatten_columns: { vessel_type_code: :vessel_type_code, voyage_type_id: :voyage_type_id } },
                                            { parent_table: :voyage_types,
                                              columns: [:voyage_type_code],
                                              flatten_columns: { voyage_type_code: :voyage_type_code } }],
                            wrapper: VesselFlat)
    end

    def for_select_vessels(args = {}, active = true) # rubocop:disable Metrics/AbcSize
      args = args.delete_if { |_, v| v.to_s.strip == '' }

      ds = DB[:vessels]
      ds = ds.join(:vessel_types, id: :vessel_type_id)
      ds = ds.where(args)
      ds = ds.where(Sequel[:vessels][:active] => active)
      ds = ds.order(:vessel_type_code)
      ds.select_map([Sequel[:vessels][:vessel_code], Sequel[:vessels][:id]])
    end

    def for_select_inactive_vessels(args = {})
      for_select_vessels(args, false)
    end
  end
end
