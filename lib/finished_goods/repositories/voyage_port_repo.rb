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
                                              columns: %i[port_code],
                                              flatten_columns: { port_code: :port_code } },
                                            { parent_table: :port_types,
                                              columns: %i[port_type_code],
                                              foreign_key: :port_type_id,
                                              flatten_columns: { port_type_code: :port_type_code } },
                                            { parent_table: :voyages,
                                              columns: %i[voyage_type_id vessel_id voyage_number year voyage_code],
                                              foreign_key: :voyage_id,
                                              flatten_columns: { voyage_type_id: :voyage_type_id,
                                                                 vessel_id: :vessel_id,
                                                                 voyage_number: :voyage_number,
                                                                 voyage_code: :voyage_code,
                                                                 year: :year } },
                                            { parent_table: :voyage_types,
                                              columns: %i[voyage_type_code],
                                              foreign_key: :voyage_type_id,
                                              flatten_columns: { voyage_type_code: :voyage_type_code } },
                                            { parent_table: :vessels,
                                              columns: %i[vessel_code],
                                              foreign_key: :vessel_id,
                                              flatten_columns: { vessel_code: :vessel_code } },
                                            { parent_table: :vessels,
                                              columns: %i[vessel_code],
                                              foreign_key: :trans_shipment_vessel_id,
                                              flatten_columns: { vessel_code: :trans_shipment_vessel } }],
                            wrapper: VoyagePortFlat)
    end
  end
end
