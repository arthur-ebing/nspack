# frozen_string_literal: true

module FinishedGoodsApp
  class LoadRepo < BaseRepo
    build_for_select :loads,
                     label: :order_number,
                     value: :id,
                     order_by: :order_number
    build_inactive_select :loads,
                          label: :order_number,
                          value: :id,
                          order_by: :order_number

    crud_calls_for :loads, name: :load, wrapper: Load

    def find_load_flat(id)
      find_with_association(:loads,
                            id,
                            parent_tables: [{ parent_table: :voyage_ports,
                                              columns: %i[port_id voyage_id],
                                              foreign_key: :pol_voyage_port_id,
                                              flatten_columns: { port_id: :pol_port_id,
                                                                 voyage_id: :voyage_id } },
                                            { parent_table: :voyage_ports,
                                              columns: %i[port_id],
                                              foreign_key: :pod_voyage_port_id,
                                              flatten_columns: { port_id: :pod_port_id } },
                                            { parent_table: :voyages,
                                              columns: %i[voyage_type_id vessel_id voyage_number year],
                                              foreign_key: :voyage_id,
                                              flatten_columns: { voyage_type_id: :voyage_type_id,
                                                                 vessel_id: :vessel_id,
                                                                 voyage_number: :voyage_number,
                                                                 year: :year } },
                                            { parent_table: :load_voyages,
                                              columns: %i[shipping_line_party_role_id
                                                          shipper_party_role_id
                                                          booking_reference
                                                          memo_pad],
                                              foreign_key: :id,
                                              flatten_columns: { shipping_line_party_role_id: :shipping_line_party_role_id,
                                                                 shipper_party_role_id: :shipper_party_role_id,
                                                                 booking_reference: :booking_reference,
                                                                 memo_pad: :memo_pad } }],
                            wrapper: LoadFlat)
    end
  end
end
