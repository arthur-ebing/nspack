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
      query = <<~SQL
        SELECT
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
        WHERE ports.id = ?
        GROUP BY ports.id, destination_cities.city_name
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      PortFlat.new(hash)
    end

    def for_select_ports(params = {}, active = true) # rubocop:disable Metrics/AbcSize
      port_type_code = params.delete(:port_type_code)
      params[:port_type_id] = DB[:port_types].where(port_type_code: port_type_code).get(:id) unless port_type_code.nil_or_empty?

      where_port_type = " AND port_type_ids @> ARRAY[#{params[:port_type_id]}]" unless params[:port_type_id].nil_or_empty?
      where_voyage_type = " AND voyage_type_ids @> ARRAY[#{params[:voyage_type_id]}]" unless params[:voyage_type_id].nil_or_empty?

      query = <<~SQL
        SELECT DISTINCT
          id,
          port_code
        FROM ports
        WHERE active = #{active}
        #{where_port_type}
        #{where_voyage_type}
      SQL
      DB[query].map { |row| [row[:port_code], row[:id]] }
    end

    def for_select_inactive_ports(params)
      for_select_ports(params, false)
    end

    def create_port(params)
      attrs = params.to_h
      attrs[:port_type_ids] = array_for_db_col(attrs[:port_type_ids]) if attrs.key?(:port_type_ids)
      attrs[:voyage_type_ids] = array_for_db_col(attrs[:voyage_type_ids]) if attrs.key?(:voyage_type_ids)

      DB[:ports].insert(attrs)
    end

    def update_port(id, params)
      attrs = params.to_h
      attrs[:port_type_ids] = array_for_db_col(attrs[:port_type_ids]) if attrs.key?(:port_type_ids)
      attrs[:voyage_type_ids] = array_for_db_col(attrs[:voyage_type_ids]) if attrs.key?(:voyage_type_ids)

      DB[:ports].where(id: id).update(attrs)
    end
  end
end
