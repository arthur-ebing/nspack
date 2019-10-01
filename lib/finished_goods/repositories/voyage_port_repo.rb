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
                                              columns: [:port_code],
                                              flatten_columns: { port_code: :port_code } },
                                            { parent_table: :vessels,
                                              columns: [:vessel_code],
                                              foreign_key: :trans_shipment_vessel_id,
                                              flatten_columns: { vessel_code: :trans_shipment_vessel } }],
                            wrapper: VoyagePortFlat)
    end
  end
end
