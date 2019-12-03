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

    def find_or_create_voyage(voyage_type_id:, vessel_id:, voyage_number:, year:, user_name: nil)
      ds = DB[:voyages]
      ds = ds.where(vessel_id: vessel_id,
                    voyage_type_id: voyage_type_id,
                    voyage_number: voyage_number,
                    year: year)
      ds = ds.where(active: true,
                    completed: false)
      voyage_id = ds.get(:id) # find existing

      if voyage_id.nil?
        voyage_id = DB[:voyages].insert(vessel_id: vessel_id,
                                        voyage_type_id: voyage_type_id,
                                        voyage_number: voyage_number,
                                        year: year) # create new voyage
        log_status(:voyages, voyage_id, 'CREATED', user_name: user_name)
      end
      voyage_id
    end

    def last_voyage_created(vessel_id)
      DB[:voyages].where(vessel_id: vessel_id).max(:id)
    end
  end
end
