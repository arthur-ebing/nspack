# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_loads;
    SQL
    # vw_loads
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_loads AS
        SELECT
            loads.id,
            loads.id AS load_id,
            loads.id AS load,
            'DN'::text || loads.id::text AS dispatch_note,
            fn_current_status ('loads', loads.id) AS status,
            --
            loads.rmt_load,
            loads.customer_party_role_id,
            fn_party_role_name (loads.customer_party_role_id) AS customer,
            loads.consignee_party_role_id,
            fn_party_role_name (loads.consignee_party_role_id) AS consignee,
            loads.billing_client_party_role_id,
            fn_party_role_name (loads.billing_client_party_role_id) AS billing_client,
            loads.exporter_party_role_id,
            fn_party_role_name (loads.exporter_party_role_id) AS exporter,
            loads.final_receiver_party_role_id,
            fn_party_role_name (loads.final_receiver_party_role_id) AS final_receiver,
            load_voyages.shipper_party_role_id,
            fn_party_role_name (load_voyages.shipper_party_role_id) AS shipper,
            load_voyages.shipping_line_party_role_id,
            fn_party_role_name (load_voyages.shipping_line_party_role_id) AS shipping_line,
            load_vehicles.haulier_party_role_id,
            fn_party_role_name(load_vehicles.haulier_party_role_id) AS haulier,
            --
            loads.final_destination_id,
            destination_cities.city_name AS final_destination,
            destination_countries.country_name AS country,
            destination_regions.destination_region_name AS region,
            --
            loads.depot_id,
            depots.depot_code AS depot,
            --
            loads.pol_voyage_port_id,
            pol_ports.port_code AS pol,
            pol_voyage_ports.etd,
            pol_voyage_ports.atd,
            COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
            --
            loads.pod_voyage_port_id,
            pod_ports.port_code AS pod,
            pod_voyage_ports.eta,
            pod_voyage_ports.ata,
            COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
            --
            loads.order_number AS internal_order_number,
            loads.customer_order_number,
            loads.customer_reference,
            loads.exporter_certificate_code,
            --
            loads.allocated,
            loads.allocated_at,
            --
            loads.shipped,
            loads.shipped_at,
            --
            loads.transfer_load,
            loads.edi_file_name,
            --
            vessels.vessel_code AS vessel,

            voyages.id AS voyage_id,
            voyages.voyage_code AS voyage,
            voyages.voyage_number,
            load_vehicles.vehicle_number,
            load_vehicles.driver_name,
            load_vehicles.driver_cell_number,
            load_vehicles.id IS NOT NULL AS truck_arrived,
            load_containers.container_code AS container,
            load_containers.internal_container_code AS internal_container,
            cargo_temperatures.temperature_code AS temp_code,
            load_voyages.booking_reference,
            loads.active,
            loads.created_at,
            loads.updated_at
        FROM loads
        --
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
        LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        --
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        --
        LEFT JOIN depots ON depots.id = loads.depot_id
        --
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
        LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
        --
        LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
        --
        LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        ;      
        ALTER TABLE public.vw_loads OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_loads;
    SQL
    # vw_loads
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_loads AS
        SELECT
            loads.id,
            loads.id AS load_id,
            'DN'::text || loads.id::text AS dispatch_note,
            fn_current_status ('loads', loads.id) AS status,
            --
            loads.rmt_load,
            loads.customer_party_role_id,
            fn_party_role_name (loads.customer_party_role_id) AS customer,
            loads.consignee_party_role_id,
            fn_party_role_name (loads.consignee_party_role_id) AS consignee,
            loads.billing_client_party_role_id,
            fn_party_role_name (loads.billing_client_party_role_id) AS billing_client,
            loads.exporter_party_role_id,
            fn_party_role_name (loads.exporter_party_role_id) AS exporter,
            loads.final_receiver_party_role_id,
            fn_party_role_name (loads.final_receiver_party_role_id) AS final_receiver,
            load_voyages.shipper_party_role_id,
            fn_party_role_name (load_voyages.shipper_party_role_id) AS shipper,
            --
            loads.final_destination_id,
            destination_cities.city_name AS final_destination,
            destination_countries.country_name AS country,
            destination_regions.destination_region_name AS region,
            --
            loads.depot_id,
            depots.depot_code AS depot,
            --
            loads.pol_voyage_port_id,
            pol_ports.port_code AS pol,
            pol_voyage_ports.etd,
            pol_voyage_ports.atd,
            COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
            --
            loads.pod_voyage_port_id,
            pod_ports.port_code AS pod,
            pod_voyage_ports.eta,
            pod_voyage_ports.ata,
            COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
            --
            loads.order_number AS internal_order_number,
            loads.edi_file_name,
            loads.customer_order_number,
            loads.customer_reference,
            loads.exporter_certificate_code,
            --
            loads.allocated,
            loads.allocated_at,
            --
            loads.shipped_at,
            loads.shipped,
            --
            loads.transfer_load,
            --
            vessels.vessel_code AS vessel,
            voyages.voyage_code AS voyage,
            voyages.voyage_number,
            load_vehicles.vehicle_number,
            load_containers.container_code AS container,
            load_containers.internal_container_code AS internal_container,
            cargo_temperatures.temperature_code AS temp_code,
            load_voyages.booking_reference,
            loads.active,
            loads.created_at,
            loads.updated_at
        FROM loads
        --
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
        LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        --
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        --
        LEFT JOIN depots ON depots.id = loads.depot_id
        --
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
        LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
        --
        LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
        --
        LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        ;      
        ALTER TABLE public.vw_loads OWNER TO postgres;
    SQL
  end
end
