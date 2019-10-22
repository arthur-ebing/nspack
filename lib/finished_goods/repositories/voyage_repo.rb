# frozen_string_literal: true

module FinishedGoodsApp
  class VoyageRepo < BaseRepo
    build_for_select :voyages,
                     label: :voyage_number,
                     value: :id,
                     order_by: :voyage_number
    build_inactive_select :voyages,
                          label: :voyage_number,
                          value: :id,
                          order_by: :voyage_number

    crud_calls_for :voyages, name: :voyage, wrapper: Voyage

    def find_voyage_flat(id)
      find_with_association(:voyages,
                            id,
                            parent_tables: [{ parent_table: :voyage_types,
                                              columns: [:voyage_type_code],
                                              flatten_columns: { voyage_type_code: :voyage_type_code } },
                                            { parent_table: :vessels,
                                              columns: [:vessel_code],
                                              flatten_columns: { vessel_code: :vessel_code } }],
                            sub_tables: [{ sub_table: :voyage_ports,
                                           columns: [:id] }],
                            wrapper: VoyageFlat)
    end

    def last_voyage_created(vessel_id)
      DB[:voyages].where(vessel_id: vessel_id).max(:id)
    end

    def lookup_voyage(voyage_type_id: nil, vessel_id: nil, voyage_number: nil, year: nil)
      return nil if voyage_type_id.nil_or_empty?
      return nil if vessel_id.nil_or_empty?

      ds = DB[:voyages]
      ds = ds.where(voyage_type_id: voyage_type_id)
      ds = ds.where(voyage_number: voyage_number)
      ds = ds.where(vessel_id: vessel_id)
      ds = ds.where(year: year)
      ds = ds.where(active: true)
      ds = ds.where(completed: false)
      ds.get(:id)
    end
  end
end
