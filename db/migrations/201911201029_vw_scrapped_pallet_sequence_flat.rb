Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_scrapped_pallet_sequence_flat AS
        SELECT ps.id,
          ps.scrapped_from_pallet_id AS pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          locations.location_short_code AS location,
          p.shipped,
          p.in_stock,
          p.inspected,
          p.reinspected,
          p.palletized,
          p.partially_palletized,
          p.allocated,
          fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at)) AS pallet_age,
          fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at)) AS inspection_age,
          fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at)) AS stock_age,
          fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)) AS cold_age,
          p.first_cold_storage_at,
          fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at)) - fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)) AS ambient_age,
          p.internal_inspection_passed,
          p.govt_inspection_passed,
          p.govt_first_inspection_at,
          p.govt_reinspection_at,
          fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at)) AS reinspection_age,
          p.shipped_at,
          p.created_at,
          p.scrapped,
          p.scrapped_at,
          ps.production_run_id,
          farms.farm_code AS farm,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          target_market_groups.target_market_group_name AS packed_tm_group,
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          ps.product_resource_allocation_id AS resource_allocation_id,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = ps.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          ps.client_size_reference AS client_size_ref,
          ps.client_product_code,
          ps.marketing_order_number AS order_number,
          seasons.season_code AS season,
          pm_subtypes.subtype_code AS pm_subtype,
          pm_types.pm_type_code AS pm_type,
          cartons_per_pallet.cartons_per_pallet AS cpp,
          pm_products.product_code AS fruit_sticker,
          p.gross_weight,
          p.gross_weight_measured_at,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          p.exit_ref,
          p.phc,
          p.stock_created_at,
          p.intake_created_at,
          p.palletized_at,
          p.partially_palletized_at,
          p.allocated_at,
          p.internal_inspection_at,
          p.internal_reinspection_at,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
          ps.verified,
          ps.verification_passed,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          ps.verification_result,
          ps.verified_at,
          pm_boms.bom_code AS bom,
          ps.extended_columns,
          ps.carton_quantity AS seq_carton_qty,
          ps.scanned_from_carton_id AS scanned_carton,
          ps.scrapped_at AS seq_scrapped_at,
          ps.exit_ref AS seq_exit_ref,
          ps.pick_ref,
          p.carton_quantity,
          ps.carton_quantity / p.carton_quantity AS pallet_size,
          p.build_status,
          fn_current_status('pallets'::text, p.id) AS status,
          fn_current_status('pallet_sequences'::text, ps.id) AS sequence_status,
          p.active,
          p.load_id,
          vessels.vessel_code AS vessel,
          voyages.voyage_code AS voyage,
          voyages.voyage_number,
          load_containers.container_code AS container,
          load_containers.internal_container_code AS internal_container,
          cargo_temperatures.temperature_code AS temp_code,
          load_vehicles.vehicle_number,
          p.cooled,
          pol_ports.port_code AS pol,
          pod_ports.port_code AS pod,
          destination_cities.city_name AS final_destination,
          fn_party_role_name(loads.customer_party_role_id) AS customer,
          fn_party_role_name(loads.consignee_party_role_id) AS consignee,
          fn_party_role_name(loads.final_receiver_party_role_id) AS final_receiver,
          fn_party_role_name(loads.exporter_party_role_id) AS exporter,
          fn_party_role_name(loads.billing_client_party_role_id) AS billing_client,
          destination_countries.country_name AS country,
          destination_regions.destination_region_name AS region,
          pod_voyage_ports.eta,
          pod_voyage_ports.ata,
          pol_voyage_ports.etd,
          pol_voyage_ports.atd,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.fruit_sticker_pm_product_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
          ps.sell_by_code,
          ps.product_chars,
          CASE
              WHEN p.scrapped THEN 'warning'::text
              ELSE NULL::text
          END AS colour_rule
         FROM pallets p
         JOIN pallet_sequences ps ON p.id = ps.scrapped_from_pallet_id
         JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
         JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
         JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
         JOIN plant_resources lines ON lines.id = ps.production_line_id
         JOIN locations ON locations.id = p.location_id
         JOIN farms ON farms.id = ps.farm_id
         JOIN pucs ON pucs.id = ps.puc_id
         JOIN orchards ON orchards.id = ps.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
         LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
         JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
         JOIN marks ON marks.id = ps.mark_id
         JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
         JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
         JOIN grades ON grades.id = ps.grade_id
         LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = ps.customer_variety_variety_id
         LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
         LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
         LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
         LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
         JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
         JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
         LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
         LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
         LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
         JOIN seasons ON seasons.id = ps.season_id
         JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
         LEFT JOIN pm_products ON pm_products.id = p.fruit_sticker_pm_product_id
         LEFT JOIN pallet_formats ON pallet_formats.id = p.pallet_format_id
         LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
         LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
         LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
         LEFT JOIN loads ON loads.id = p.load_id
         LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
         LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
         LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
         LEFT JOIN vessels ON vessels.id = voyages.vessel_id
         LEFT JOIN load_containers ON load_containers.load_id = loads.id
         LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
         LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
         LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
         LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
         LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
         LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
         LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        ORDER BY p.pallet_number, ps.pallet_sequence_number;
        
        ALTER TABLE public.vw_scrapped_pallet_sequence_flat
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;
    SQL
  end
end
