# frozen_string_literal: true

module FinishedGoodsApp
  class VoyagePortRepo < BaseRepo
    build_for_select :voyage_ports,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :voyage_ports,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :voyage_ports, name: :voyage_port, wrapper: VoyagePort

    def find_voyage_port_flat(id)
      find_with_association(:voyage_ports,
                            id,
                            parent_tables: [{ parent_table: :ports,
                                              columns: %i[port_code port_type_id],
                                              flatten_columns: { port_code: :port_code, port_type_id: :port_type_id } },
                                            { parent_table: :port_types,
                                              columns: %i[port_type_code],
                                              foreign_key: :port_type_id,
                                              flatten_columns: { port_type_code: :port_type_code } },
                                            { parent_table: :vessels,
                                              columns: %i[vessel_code],
                                              foreign_key: :trans_shipment_vessel_id,
                                              flatten_columns: { vessel_code: :trans_shipment_vessel } }],
                            wrapper: VoyagePortFlat)
    end

    def for_select_voyage_ports_by_port_type(port_type_code)
      DB[:voyage_ports]
        .join(:ports, id: :port_id)
        .join(:port_types, id: :port_type_id)
        .where(port_type_code: port_type_code)
        .select_map([Sequel[:ports][:port_code], Sequel[:voyage_ports][:id]])
    end
  end
end
