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
                                            { parent_table: :destination_cities,
                                              columns: %i[city_name],
                                              foreign_key: :city_id,
                                              flatten_columns: { city_name: :city_name } },
                                            { parent_table: :port_types,
                                              columns: %i[port_type_code],
                                              flatten_columns: { port_type_code: :port_type_code } }],
                            wrapper: PortFlat)
    end

    def for_select_ports(args = nil) # rubocop:disable Metrics/AbcSize
      ds = DB[:port_types]
      ds = ds.join(:ports, port_type_id: :id)
      ds = ds.join(:voyage_types, id: :voyage_type_id)
      ds = ds.where(args) unless args.nil?
      ds = ds.where(Sequel[:ports][:active] => true)
      ds = ds.order(:port_code)
      ds.select_map([Sequel[:ports][:port_code], Sequel[:ports][:id]])
    end

    def for_select_inactive_ports(args = nil) # rubocop:disable Metrics/AbcSize
      ds = DB[:port_types]
      ds = ds.join(:ports, port_type_id: :id)
      ds = ds.join(:voyage_types, id: :voyage_type_id)
      ds = ds.where(args) unless args.nil?
      ds = ds.where(Sequel[:ports][:active] => false)
      ds = ds.order(:port_code)
      ds.select_map([Sequel[:ports][:port_code], Sequel[:ports][:id]])
    end
  end
end
