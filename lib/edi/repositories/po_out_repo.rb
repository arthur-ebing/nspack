# frozen_string_literal: true

module EdiApp
  class PoOutRepo < BaseRepo
    def po_header_row(load_id)
      query = <<~SQL
        SELECT
          loads.id AS load_id,
          load_vehicles.vehicle_number AS load_ref,
          CASE WHEN load_containers.id IS NULL THEN 'R' ELSE 'F' END AS load_type,
          loads.shipped_at AS tk_date,
          loads.shipped_at AS start_date,
          loads.shipped_at AS end_date,
          loads.shipped_at AS departure_date,
          fn_party_role_name(load_vehicles.haulier_party_role_id) AS carrier,
          (SELECT COUNT(*) FROM pallets WHERE load_id = loads.id) AS plt_qty,
          (SELECT SUM(carton_quantity) FROM pallets WHERE load_id = loads.id) AS ctn_qty,
          depots.depot_code AS next_code,
          loads.customer_order_number AS master_ord,
          EXTRACT(YEAR FROM seasons.end_date) AS season,
          loads.id AS trip_no,
          COALESCE(pol_voyage_ports.ata, pol_voyage_ports.eta, loads.shipped_at) AS arr_date,
          COALESCE(pol_voyage_ports.ata, pol_voyage_ports.eta, loads.shipped_at) AS arr_time,
          COALESCE(pod_voyage_ports.atd, pod_voyage_ports.etd, loads.shipped_at) AS dep_date,
          COALESCE(pod_voyage_ports.atd, pod_voyage_ports.etd, loads.shipped_at) AS dep_time
        FROM loads
        JOIN pallets ON pallets.load_id = loads.id AND NOT scrapped
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id AND NOT scrapped
        JOIN load_voyages ON load_voyages.load_id = loads.id
        JOIN voyages ON voyages.id = load_voyages.voyage_id
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        JOIN load_vehicles ON load_vehicles.load_id = loads.id
        JOIN depots ON depots.id = loads.depot_id
        JOIN seasons ON seasons.id = pallet_sequences.season_id
        WHERE loads.id = ? LIMIT 1
      SQL
      DB[query, load_id].first
    end

    def po_details(load_id)
      query = <<~SQL
        SELECT
          loads.id AS load_id,
          load_containers.container_code AS container,
          loads.shipped_at AS stuff_date,
          cargo_temperatures.set_point_temperature AS temp_set,
          pol_ports.port_code AS disch_port,
          voyages.voyage_number AS ship_number,
          pallet_bases.edi_out_pallet_base AS pallet_btype,
          vessels.vessel_code AS ship_name,
          fn_party_role_name(load_voyages.shipping_line_party_role_id) AS ship_line,
          loads.id AS doc_no,
          fn_party_role_name(loads.exporter_party_role_id) AS sender,
          fn_party_role_name(load_voyages.shipper_party_role_id) AS agent,
          fn_party_role_name(load_voyages.shipper_party_role_id) AS ship_sender,
          fn_party_role_name(load_voyages.shipper_party_role_id) AS ship_agent,
          marketing_org.short_description AS orgzn,
          (SELECT SUM(carton_quantity) FROM pallets p WHERE p.load_id = loads.id) AS ctn_qty,
          (SELECT COUNT(*) FROM pallets p WHERE p.load_id = loads.id) AS plt_qty,
          load_containers.container_temperature_rhine AS ryan_no_old,
          SUBSTR(container_stack_types.stack_type_code, 1, 1) AS container_type,
          SUBSTR(container_stack_types.stack_type_code, 1, 1) AS container_size,
          load_containers.container_seal_code AS seal_no,
          0 AS consec_no,
          0 AS cto_no,
          load_containers.tare_weight AS container_tare_weight,
          load_containers.verified_gross_weight AS container_gross_mass,
          fn_party_role_name(loads.exporter_party_role_id) AS responsible_party,

          CASE WHEN destination_countries.country_name = 'ZA' THEN 'L' ELSE 'E' END AS channel,    -- THIS IS NOT SAFE ENOuGH... (should dest_countries have country_code...)
          loads.id AS cons_no,
          loads.shipped_at AS cons_date,
          EXTRACT(YEAR FROM seasons.end_date) AS season,
          loads.customer_order_number AS client_ref,
          loads.customer_order_number AS order_no,
          (SELECT SUM(carton_quantity) FROM pallets p WHERE p.load_id = loads.id) AS cnts_on_truck
        FROM loads
        JOIN pallets ON pallets.load_id = loads.id AND NOT scrapped
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id AND NOT scrapped
        JOIN load_voyages ON load_voyages.load_id = loads.id
        JOIN voyages ON voyages.id = load_voyages.voyage_id
        JOIN vessels ON vessels.id = voyages.vessel_id
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        JOIN load_vehicles ON load_vehicles.load_id = loads.id
        JOIN depots ON depots.id = loads.depot_id
        JOIN seasons ON seasons.id = pallet_sequences.season_id
        LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
        LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        JOIN party_roles mpr ON mpr.id = pallet_sequences.marketing_org_party_role_id
        JOIN organizations marketing_org ON marketing_org.party_id = mpr.party_id
        LEFT OUTER JOIN container_stack_types ON container_stack_types.id = load_containers.stack_type_id
        LEFT OUTER JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT OUTER JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        WHERE loads.id = ?
      SQL
      DB[query, load_id].all
    end
  end
end
