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
                            parent_tables: [{ parent_table: :voyage_types, columns: [:voyage_type_code], flatten_columns: { voyage_type_code: :voyage_type_code } },
                                            { parent_table: :port_types, columns: [:port_type_code], flatten_columns: { port_type_code: :port_type_code } }],
                            wrapper: PortFlat)
    end
  end
end
