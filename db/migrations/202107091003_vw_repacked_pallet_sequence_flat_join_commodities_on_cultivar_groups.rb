Sequel.migration do
  up do
    # vw_repacked_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_repacked_pallet_sequence_flat;
      CREATE VIEW public.vw_repacked_pallet_sequence_flat AS
       SELECT ps.id,
          ps.repacked_from_pallet_id,
          scrapped_ps.pallet_number AS repacked_from_pallet_number,
          ps.pallet_id,
          ps.pallet_number AS repacked_to_pallet_number,
          ifr.failure_reason AS inspection_failure_reason,
          p.repacked,
          p.repacked_at,
          ps.pallet_sequence_number,
          locations.location_long_code::text AS location,
          cultivars.cultivar_name AS cultivar,
          ps.carton_quantity,
          p.carton_quantity AS pallet_carton_quantity,
          ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
          floor(fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at))) - floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS ambient_age,
          ps.created_at,
          p.palletized_at,
          p.govt_first_inspection_at,
          p.govt_first_inspection_at::date AS govt_first_inspection_date,
          p.govt_reinspection_at::date AS govt_reinspection_date,
          p.govt_inspection_passed,
          inspected_dest_country.country_name AS inspected_dest_country,
          p.shipped_at,
          p.govt_reinspection_at,
          p.allocated_at,
          ps.verified_at,
          p.allocated,
          p.load_id,
          p.shipped,
          p.in_stock,
          p.inspected,
          p.palletized,
          ps.production_run_id,
          farms.farm_code AS farm,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          grades.grade_code AS grade,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          fruit_size_references.size_reference AS size_ref,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          standard_pack_codes.standard_pack_code AS std_pack,
          target_market_groups.target_market_group_name AS packed_tm_group,
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          pm_products.product_code AS fruit_sticker,
          pm_products_2.product_code AS fruit_sticker_2,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          p.gross_weight,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          basic_pack_codes.basic_pack_code AS basic_pack,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          ps.pick_ref,
          p.phc,
          ps.verification_result,
          p.scrapped_at,
          p.scrapped,
          p.partially_palletized,
          p.reinspected,
          ps.verified,
          ps.verification_passed,
          fn_current_status('pallets'::text, p.id) AS status,
          p.build_status,
          p.active,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.temp_tail,
          p.depot_pallet,
          edi_in_transactions.file_name AS edi_in_file,
          p.edi_in_consignment_note_number,
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.target_customer_party_role_id,
          fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
          cvv.marketing_variety_code AS customer_variety,
          lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) AS consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons,
              CASE
                  WHEN p.scrapped THEN 'warning'::text
                  WHEN p.shipped THEN 'inactive'::text
                  WHEN p.allocated THEN 'ready'::text
                  WHEN p.in_stock THEN 'ok'::text
                  WHEN p.palletized OR p.partially_palletized THEN 'inprogress'::text
                  WHEN p.inspected AND NOT p.govt_inspection_passed THEN 'error'::text
                  WHEN ps.verified AND NOT ps.verification_passed THEN 'error'::text
                  ELSE NULL::text
              END AS colour_rule

         FROM pallets p
           JOIN pallet_sequences ps ON p.id = ps.pallet_id
           JOIN pallets scrapped_pallets ON scrapped_pallets.id = ps.repacked_from_pallet_id
           JOIN pallet_sequences scrapped_ps ON scrapped_pallets.id = scrapped_ps.scrapped_from_pallet_id
           LEFT JOIN govt_inspection_pallets gip ON gip.pallet_id = scrapped_pallets.id
           LEFT JOIN inspection_failure_reasons ifr ON ifr.id = gip.failure_reason_id
           LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
           LEFT JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
           LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = p.palletizing_bay_resource_id
           JOIN locations ON locations.id = p.location_id
           JOIN farms ON farms.id = ps.farm_id
           LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
           JOIN production_regions ON production_regions.id = farms.pdn_region_id
           JOIN pucs ON pucs.id = ps.puc_id
           JOIN orchards ON orchards.id = ps.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
           JOIN marks ON marks.id = ps.mark_id
           JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
           JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
           JOIN grades ON grades.id = ps.grade_id
           LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
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
           LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = p.fruit_sticker_pm_product_2_id
           LEFT JOIN pallet_formats ON pallet_formats.id = p.pallet_format_id
           LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
           LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
           LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
           LEFT JOIN loads ON loads.id = p.load_id
           LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
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
           LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = p.last_govt_inspection_pallet_id
           LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
           LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id
           LEFT JOIN edi_in_transactions ON edi_in_transactions.id = p.edi_in_transaction_id
           LEFT JOIN depots ON depots.id = loads.depot_id
           LEFT JOIN ( SELECT sq.id,
                  COALESCE(btrim(array_agg(orchard_test_types.test_type_code)::text), ''::text) <> ''::text AS failed_otmc,
                  array_agg(orchard_test_types.test_type_code) AS failed_otmc_results
                 FROM pallet_sequences sq
                   JOIN orchard_test_types ON orchard_test_types.id = ANY (sq.failed_otmc_results)
                GROUP BY sq.id) otmc ON otmc.id = ps.id
        WHERE p.repacked AND p.in_stock = false
        ORDER BY p.repacked_at DESC, p.pallet_number DESC;
      
      ALTER TABLE public.vw_repacked_pallet_sequence_flat
          OWNER TO postgres;
    SQL
  end

  down do
    # vw_repacked_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_repacked_pallet_sequence_flat;
      CREATE OR REPLACE VIEW public.vw_repacked_pallet_sequence_flat AS
       SELECT ps.id,
          ps.repacked_from_pallet_id,
          scrapped_ps.pallet_number AS repacked_from_pallet_number,
          ps.pallet_id,
          ps.pallet_number AS repacked_to_pallet_number,
          ifr.failure_reason AS inspection_failure_reason,
          p.repacked,
          p.repacked_at,
          ps.pallet_sequence_number,
          locations.location_long_code::text AS location,
          cultivars.cultivar_name AS cultivar,
          ps.carton_quantity,
          p.carton_quantity AS pallet_carton_quantity,
          ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
          floor(fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at))) - floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS ambient_age,
          ps.created_at,
          p.palletized_at,
          p.govt_first_inspection_at,
          p.govt_first_inspection_at::date AS govt_first_inspection_date,
          p.govt_reinspection_at::date AS govt_reinspection_date,
          p.govt_inspection_passed,
          inspected_dest_country.country_name AS inspected_dest_country,
          p.shipped_at,
          p.govt_reinspection_at,
          p.allocated_at,
          ps.verified_at,
          p.allocated,
          p.load_id,
          p.shipped,
          p.in_stock,
          p.inspected,
          p.palletized,
          ps.production_run_id,
          farms.farm_code AS farm,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          grades.grade_code AS grade,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          fruit_size_references.size_reference AS size_ref,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          standard_pack_codes.standard_pack_code AS std_pack,
          target_market_groups.target_market_group_name AS packed_tm_group,
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          pm_products.product_code AS fruit_sticker,
          pm_products_2.product_code AS fruit_sticker_2,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          p.gross_weight,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          basic_pack_codes.basic_pack_code AS basic_pack,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          ps.pick_ref,
          p.phc,
          ps.verification_result,
          p.scrapped_at,
          p.scrapped,
          p.partially_palletized,
          p.reinspected,
          ps.verified,
          ps.verification_passed,
          fn_current_status('pallets'::text, p.id) AS status,
          p.build_status,
          p.active,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.temp_tail,
          p.depot_pallet,
          edi_in_transactions.file_name AS edi_in_file,
          p.edi_in_consignment_note_number,
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.target_customer_party_role_id,
          fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
          cvv.marketing_variety_code AS customer_variety,
          lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) AS consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons,
              CASE
                  WHEN p.scrapped THEN 'warning'::text
                  WHEN p.shipped THEN 'inactive'::text
                  WHEN p.allocated THEN 'ready'::text
                  WHEN p.in_stock THEN 'ok'::text
                  WHEN p.palletized OR p.partially_palletized THEN 'inprogress'::text
                  WHEN p.inspected AND NOT p.govt_inspection_passed THEN 'error'::text
                  WHEN ps.verified AND NOT ps.verification_passed THEN 'error'::text
                  ELSE NULL::text
              END AS colour_rule

         FROM pallets p
           JOIN pallet_sequences ps ON p.id = ps.pallet_id
           JOIN pallets scrapped_pallets ON scrapped_pallets.id = ps.repacked_from_pallet_id
           JOIN pallet_sequences scrapped_ps ON scrapped_pallets.id = scrapped_ps.scrapped_from_pallet_id
           LEFT JOIN govt_inspection_pallets gip ON gip.pallet_id = scrapped_pallets.id
           LEFT JOIN inspection_failure_reasons ifr ON ifr.id = gip.failure_reason_id
           LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
           LEFT JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
           LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = p.palletizing_bay_resource_id
           JOIN locations ON locations.id = p.location_id
           JOIN farms ON farms.id = ps.farm_id
           LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
           JOIN production_regions ON production_regions.id = farms.pdn_region_id
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
           LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
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
           LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = p.fruit_sticker_pm_product_2_id
           LEFT JOIN pallet_formats ON pallet_formats.id = p.pallet_format_id
           LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
           LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
           LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
           LEFT JOIN loads ON loads.id = p.load_id
           LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
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
           LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = p.last_govt_inspection_pallet_id
           LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
           LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id
           LEFT JOIN edi_in_transactions ON edi_in_transactions.id = p.edi_in_transaction_id
           LEFT JOIN depots ON depots.id = loads.depot_id
           LEFT JOIN ( SELECT sq.id,
                  COALESCE(btrim(array_agg(orchard_test_types.test_type_code)::text), ''::text) <> ''::text AS failed_otmc,
                  array_agg(orchard_test_types.test_type_code) AS failed_otmc_results
                 FROM pallet_sequences sq
                   JOIN orchard_test_types ON orchard_test_types.id = ANY (sq.failed_otmc_results)
                GROUP BY sq.id) otmc ON otmc.id = ps.id
        WHERE p.repacked AND p.in_stock = false
        ORDER BY p.repacked_at DESC, p.pallet_number DESC;
      
      ALTER TABLE public.vw_repacked_pallet_sequence_flat
          OWNER TO postgres;
    SQL
  end
end
