# frozen_string_literal: true

module MasterfilesApp
  class PortRepo < BaseRepo
    build_for_select :ports,
                     label: :port_code,
                     value: :id,
                     order_by: :port_code
    build_inactive_select :ports,
                          label: :port_code,
                          value: :id,
                          order_by: :port_code

    crud_calls_for :ports, name: :port, wrapper: Port

    def find_port_flat(id)
      find_with_association(:ports,
                            id,
                            parent_tables: [{ parent_table: :voyage_types,
                                              columns: %i[voyage_type_code],
                                              flatten_columns: { voyage_type_code: :voyage_type_code } },
                                            { parent_table: :port_types,
                                              columns: %i[port_type_code],
                                              flatten_columns: { port_type_code: :port_type_code } }],
                            wrapper: PortFlat)
    end

    def for_select_ports_by_type_id(port_type_id)
      port_type_id = port_type_id.to_s.empty? ? '0' : port_type_id
      DB[:ports].where(port_type_id: port_type_id).order(:port_code).select_map(%i[port_code id])
    end
  end
end
