# frozen_string_literal: true

module EdiApp
  class PoOutRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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
          CASE WHEN loads.transfer_load THEN
            'is_transfer'
          ELSE
            'is_final_load_out'
          END AS extra_chars,
          fn_party_role_org_code(load_vehicles.haulier_party_role_id) AS carrier,
          fn_party_role_org_code(loads.customer_party_role_id) AS customer,
          (SELECT COUNT(*) FROM pallets WHERE load_id = loads.id) AS plt_qty,
          (SELECT SUM(carton_quantity) FROM pallets WHERE load_id = loads.id) AS ctn_qty,
          depots.depot_code AS next_code,
          depots.depot_code AS locn_code,
          loads.customer_order_number AS master_ord,
          EXTRACT(YEAR FROM seasons.end_date)::integer AS season,
          loads.id AS trip_no,
          COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta, loads.shipped_at) AS arr_date,
          COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta, loads.shipped_at) AS arr_time,
          COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd, loads.shipped_at) AS dep_date,
          COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd, loads.shipped_at) AS dep_time
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
          pod_ports.port_code AS disch_port,
          voyages.voyage_number AS ship_number,
          pallet_bases.edi_out_pallet_base AS pallet_btype,
          vessels.vessel_code AS ship_name,
          fn_party_role_org_code(load_voyages.shipping_line_party_role_id) AS ship_line,
          loads.id AS doc_no,
          fn_party_role_org_code(loads.exporter_party_role_id) AS sender,
          fn_party_role_org_code(load_voyages.shipper_party_role_id) AS agent,
          fn_party_role_org_code(load_voyages.shipper_party_role_id) AS ship_sender,
          fn_party_role_org_code(load_voyages.shipper_party_role_id) AS ship_agent,
          marketing_org.short_description AS orgzn,
          (SELECT SUM(carton_quantity) FROM pallets p WHERE p.load_id = loads.id) AS tot_ctn_qty,
          (SELECT COUNT(*) FROM pallets p WHERE p.load_id = loads.id) AS tot_plt_qty,
          load_containers.container_temperature_rhine AS ryan_no_old,
          SUBSTR(container_stack_types.stack_type_code, 1, 1) AS container_type,
          SUBSTR(container_stack_types.stack_type_code, 1, 1) AS container_size,
          load_containers.container_seal_code AS seal_no,
          0 AS consec_no,
          0 AS cto_no,
          load_containers.tare_weight AS container_tare_weight,
          load_containers.verified_gross_weight AS container_gross_mass,
          fn_party_role_org_code(loads.exporter_party_role_id) AS responsible_party,
          CASE WHEN destination_countries.iso_country_code = 'ZA' THEN 'L' ELSE 'E' END AS channel,
          loads.id AS cons_no,
          loads.shipped_at AS cons_date,
          EXTRACT(YEAR FROM seasons.end_date)::integer AS season,
          loads.customer_order_number AS client_ref,
          loads.customer_order_number AS order_no,
          (SELECT SUM(carton_quantity) FROM pallets p WHERE p.load_id = loads.id) AS cnts_on_truck,

          depots.depot_code AS dest_locn,
          depots.depot_code AS orig_depot,
          CASE WHEN govt_inspection_sheets.use_inspection_destination_for_load_out THEN
            (SELECT destination_regions.destination_region_name
              FROM destination_regions_tm_groups
              LEFT JOIN destination_regions ON destination_regions.id = destination_regions_tm_groups.destination_region_id
              WHERE destination_regions_tm_groups.target_market_group_id = pallet_sequences.packed_tm_group_id
              LIMIT 1)
          ELSE
            destination_regions.destination_region_name
          END AS target_region,
          CASE WHEN govt_inspection_sheets.use_inspection_destination_for_load_out THEN
            target_market_groups.target_market_group_name
          ELSE
            destination_countries.iso_country_code
          END AS target_country,
          substring(pallet_sequences.pallet_number from '.........$') AS pallet_id,
          pallet_sequences.pallet_sequence_number AS seq_no,
          govt_inspection_sheets.id AS consignment_number,
          COALESCE(pallets.intake_created_at, pallets.govt_reinspection_at, pallets.govt_first_inspection_at, current_timestamp) AS intake_date,
          COALESCE(pallets.intake_created_at, pallets.govt_first_inspection_at, current_timestamp) AS orig_intake,
          substring(commodity_groups.code FROM '..') AS comm_grp,
          commodities.code AS commodity,
          marketing_varieties.marketing_variety_code AS variety,
          standard_pack_codes.standard_pack_code AS pack,
          grades.grade_code AS grade,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi,
                            commodities.use_size_ref_for_edi,
                            fruit_size_references.edi_out_code,
                            fruit_size_references.size_reference,
                            fruit_actual_counts_for_packs.actual_count_for_pack) AS size_count,
          marks.mark_code AS mark,
          COALESCE(inventory_codes.edi_out_inventory_code, inventory_codes.inventory_code) AS inv_code,
          govt_inspection_sheets.inspection_point AS inspect_pnt,
          inspectors.inspector_code AS inspector,
          pallet_sequences.pick_ref,
          loads.shipped_at AS shipped_date,
          pallet_sequences.product_chars AS prod_char,
          govt_inspection_sheets.id AS orig_cons,
          target_market_groups.target_market_group_name AS targ_mkt,
          pucs.puc_code AS farm,
          pallet_sequences.carton_quantity AS ctn_qty,
          1 AS plt_qty,
          CASE WHEN (SELECT count(*) FROM pallet_sequences m WHERE m.pallet_id = pallet_sequences.pallet_id AND NOT scrapped) > 1 THEN 'Y' ELSE 'N' END AS mixed_ind,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at) AS inspec_date,
          pallets.govt_first_inspection_at AS original_inspec_date,
          pallets.first_cold_storage_at AS cold_date,
          COALESCE(pallets.stock_created_at, pallets.created_at) AS transaction_date,
          COALESCE(pallets.stock_created_at, pallets.created_at) AS transaction_time,
          pallet_bases.edi_out_pallet_base AS pallet_btype,
          pallets.pallet_number AS sscc,
          govt_inspection_sheets.id AS waybill_no,
          pallet_sequences.sell_by_code AS sellbycode,
          pallets.pallet_number AS combo_sscc,
          pallets.phc AS packh_code,
          orchards.orchard_code AS orchard,
          CASE WHEN pallet_sequences.pallet_sequence_number = 1 THEN
            pallets.gross_weight
          ELSE
            0::numeric
          END AS pallet_gross_mass,
          pallets.gross_weight_measured_at AS weighing_date,
          pallets.gross_weight_measured_at AS weighing_time,
          pallet_sequences.nett_weight AS mass,
          pallets.temp_tail AS temp_device_id,
          pallet_sequences.phyto_data

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
        LEFT OUTER JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
        LEFT OUTER JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
        LEFT OUTER JOIN inspectors ON inspectors.id = govt_inspection_sheets.inspector_id
        LEFT OUTER JOIN container_stack_types ON container_stack_types.id = load_containers.stack_type_id
        LEFT OUTER JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT OUTER JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        LEFT OUTER JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
        JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        JOIN commodity_groups ON commodity_groups.id = commodities.commodity_group_id
        JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
        JOIN marks ON marks.id = pallet_sequences.mark_id
        JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
        JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
        JOIN grades ON grades.id = pallet_sequences.grade_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
        JOIN pucs ON pucs.id = pallet_sequences.puc_id
        JOIN orchards ON orchards.id = pallet_sequences.orchard_id
        WHERE loads.id = ?
      SQL
      DB[query, load_id].all
    end

    def store_edi_filename(file_name, record_id)
      DB[:loads].where(id: record_id).update(edi_file_name: file_name)
      log_status(:loads, record_id, 'PO SENT', user_name: 'System', comment: file_name)
    end

    def log_po_fail(record_id, message)
      log_status(:loads, record_id, 'PO SEND FAILURE', user_name: 'System', comment: message)
    end
  end
end
