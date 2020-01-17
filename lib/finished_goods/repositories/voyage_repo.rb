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

    def find_voyage_with_ports(params) # rubocop:disable Metrics/AbcSize
      ds = DB[:voyages]
      ds = ds.join_table(:left, Sequel[:voyage_ports].as(:pol_voyage_port), voyage_id: Sequel[:voyages][:id])
      ds = ds.join_table(:left, Sequel[:voyage_ports].as(:pod_voyage_port), voyage_id: Sequel[:voyages][:id])
      ds = ds.where(voyage_type_id: params[:voyage_type_id], vessel_id: params[:vessel_id], voyage_number: params[:voyage_number], year: params[:year])
      ds = ds.where(Sequel[:voyages][:active] => params[:active])
      ds = ds.where(Sequel[:voyages][:completed] => params[:completed])
      ds = ds.where(Sequel[:pol_voyage_port][:port_id] => params[:pol_port_id])
      ds = ds.where(Sequel[:pod_voyage_port][:port_id] => params[:pod_port_id])
      { voyage_id: ds.get(Sequel[:voyages][:id]), pol_voyage_port_id: ds.get(Sequel[:pol_voyage_port][:id]), pod_voyage_port_id: ds.get(Sequel[:pod_voyage_port][:id]) }
    end
  end
end
