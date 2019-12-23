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
      query = "SELECT
                    ports.id,
                    ports.port_code,
                    ports.description,
                    ports.port_type_ids,
                    string_agg(distinct port_types.port_type_code, ', ') AS port_type_codes,
                    ports.voyage_type_ids,
                    string_agg(distinct voyage_types.voyage_type_code, ', ') AS voyage_type_codes,
                    ports.city_id,
                    destination_cities.city_name AS city_name,
                    ports.active
                FROM ports
                LEFT JOIN destination_cities ON destination_cities.id = ports.city_id
                JOIN port_types ON port_types.id = ANY(ports.port_type_ids)
                JOIN voyage_types ON voyage_types.id = ANY(ports.voyage_type_ids)
                WHERE ports.id = #{id}
                GROUP BY ports.id, destination_cities.city_name"
      hash = DB[query].first
      return nil if hash.nil?

      PortFlat.new(hash)
    end

    def for_select_ports(args = {})
      query = 'SELECT *,
               ports.id AS id,
               port_types.id AS port_type_id,
               voyage_types.id AS voyage_type_id
               FROM ports
               LEFT JOIN destination_cities ON destination_cities.id = ports.city_id
               JOIN port_types ON port_types.id = ANY(ports.port_type_ids)
               JOIN voyage_types ON voyage_types.id = ANY(ports.voyage_type_ids)
               WHERE ports.active = true'
      hash = DB[query].all
      args.each { |k, v| hash = hash.find_all { |row| row[k].to_s == v.to_s } }
      hash.map { |row| [row[:port_code],  row[:id].to_i] }
    end

    def for_select_inactive_ports(args = {})
      query = 'SELECT *,
               ports.id AS id,
               port_types.id AS port_type_id,
               voyage_types.id AS voyage_type_id
               FROM ports
               LEFT JOIN destination_cities ON destination_cities.id = ports.city_id
               JOIN port_types ON port_types.id = ANY(ports.port_type_ids)
               JOIN voyage_types ON voyage_types.id = ANY(ports.voyage_type_ids)
               WHERE ports.active = false'
      hash = DB[query].all
      args.each { |k, v| hash = hash.find_all { |row| row[k].to_s == v.to_s } }
      hash.map { |row| [row[:port_code],  row[:id].to_i] }
    end
  end
end
