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
                            parent_tables: [{ parent_table: :voyage_types, columns: [:voyage_type_code], flatten_columns: { voyage_type_code: :voyage_type_code } },
                                            { parent_table: :vessels, columns: [:vessel_code], flatten_columns: { vessel_code: :vessel_code } }],
                            wrapper: VoyageFlat)
    end

    def last_voyage_created(vessel_id)
      DB[:voyages].where(vessel_id: vessel_id).max(:id)
    end
  end
end
