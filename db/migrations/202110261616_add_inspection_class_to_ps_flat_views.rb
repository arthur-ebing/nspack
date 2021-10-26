Sequel.migration do
  up do

    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      
      DROP VIEW public.vw_pallet_sequences;

      CREATE OR REPLACE VIEW public.vw_pallet_sequences AS
        SELECT ps.id,
        ps.id AS pallet_sequence_id,
        fn_current_status('pallet_sequences'::text, ps.id) AS status,
        ps.pallet_id,
        ps.pallet_number,
        ps.pallet_sequence_number,
        ps.created_at AS packed_at,
        ps.created_at::date AS packed_date,
        date_part('week'::text, ps.created_at) AS packed_week,
        ps.production_run_id,
        ps.production_run_id AS production_run,
        ps.season_id,
        seasons.season_code AS season,
        ps.farm_id,
        farms.farm_code AS farm,
        farm_groups.farm_group_code AS farm_group,
        production_regions.production_region_code AS production_region,
        ps.puc_id,
        pucs.puc_code AS puc,
        ps.orchard_id,
        orchards.orchard_code AS orchard,
        commodities.id AS commodity_id,
        commodities.code AS commodity,
        ps.cultivar_group_id,
        cultivar_groups.cultivar_group_code AS cultivar_group,
        ps.cultivar_id,
        cultivars.cultivar_name,
        cultivars.cultivar_code AS cultivar,
        ps.product_resource_allocation_id AS resource_allocation_id,
        ps.packhouse_resource_id,
        packhouses.plant_resource_code AS packhouse,
        ps.production_line_id,
        lines.plant_resource_code AS line,
        ps.marketing_variety_id,
        marketing_varieties.marketing_variety_code AS marketing_variety,
        ps.customer_variety_id,
        customer_varieties.variety_as_customer_variety_id,
        customer_marketing_varieties.marketing_variety_code AS customer_marketing_variety,
        ps.marketing_org_party_role_id,
        fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
        ps.marketing_puc_id,
        marketing_pucs.puc_code AS marketing_puc,
        ps.marketing_orchard_id,
        registered_orchards.orchard_code AS marketing_orchard,
        ps.marketing_order_number,
        ps.std_fruit_size_count_id,
        std_fruit_size_counts.size_count_value AS standard_size,
        std_fruit_size_counts.size_count_interval_group AS count_group,
        round((ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5), 2) AS standard_count,
        ps.basic_pack_code_id AS basic_pack_id,
        basic_pack_codes.basic_pack_code AS basic_pack,
        ps.standard_pack_code_id AS standard_pack_id,
        standard_pack_codes.standard_pack_code AS standard_pack,
        ps.fruit_actual_counts_for_pack_id,
        ps.fruit_actual_counts_for_pack_id AS actual_count_id,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
        ps.fruit_size_reference_id,
        ps.fruit_size_reference_id AS size_reference_id,
        fruit_size_references.size_reference AS size_reference,
        ps.packed_tm_group_id,
        target_market_groups.target_market_group_name AS packed_tm_group,
        ps.mark_id,
        marks.mark_code AS mark,
        ps.pm_mark_id,
        pm_marks.packaging_marks,
        ps.inventory_code_id,
        ps.inventory_code_id AS inventory_id,
        inventory_codes.inventory_code,
        ps.pallet_format_id,
        pallet_formats.description AS pallet_format,
        ps.cartons_per_pallet_id,
        cartons_per_pallet.cartons_per_pallet,
        ps.pm_bom_id,
        pm_boms.bom_code,
        pm_boms.system_code,
        ps.extended_columns,
        ps.client_size_reference,
        ps.client_product_code AS client_product,
        ps.treatment_ids,
        ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
          FROM treatments
          WHERE treatments.id = ANY (ps.treatment_ids)
          GROUP BY ps.id) AS treatments,
        ps.pm_type_id,
        pm_types.pm_type_code AS pm_type,
        ps.pm_subtype_id,
        pm_subtypes.subtype_code AS pm_subtype,
        ps.carton_quantity,
        ps.scanned_from_carton_id AS scanned_carton,
        ps.scrapped_at,
        ps.exit_ref AS exit_reference,
        ps.verification_result,
        ps.pallet_verification_failure_reason_id,
        pallet_verification_failure_reasons.reason AS verification_failure_reason,
        ps.verified,
        ps.verified_by,
        ps.verified_at,
        ps.verification_passed,
        round(ps.nett_weight, 2) AS nett_weight,
        ps.pick_ref AS pick_reference,
        ps.grade_id,
        grades.grade_code AS grade,
        grades.rmt_grade,
        grades.inspection_class,
        ps.scrapped_from_pallet_id,
        ps.removed_from_pallet,
        ps.removed_from_pallet_id,
        ps.removed_from_pallet_at,
        ps.sell_by_code,
        ps.product_chars,
        ps.depot_pallet,
        ps.personnel_identifier_id,
        personnel_identifiers.hardware_type,
        personnel_identifiers.identifier,
        ps.contract_worker_id,
        ps.repacked_at IS NOT NULL AS repacked,
        ps.repacked_at,
        ps.repacked_from_pallet_id,
        (SELECT pallets.pallet_number
         FROM pallets
         WHERE pallets.id = ps.repacked_from_pallet_id) AS repacked_from_pallet_number,
        ps.failed_otmc_results IS NOT NULL AS failed_otmc,
        ps.failed_otmc_results AS failed_otmc_result_ids,
        (SELECT array_agg(DISTINCT orchard_test_types.test_type_code ORDER BY orchard_test_types.test_type_code) AS array_agg
         FROM orchard_test_types
         WHERE orchard_test_types.id = ANY (ps.failed_otmc_results)
         GROUP BY ps.id) AS failed_otmc_results,
        ps.phyto_data,
        ps.active,
        ps.created_by,
        ps.created_at,
        ps.updated_at,
        ps.target_customer_party_role_id,
        fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
        target_markets.target_market_name AS target_market,
        ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS standard_cartons,
        ps.rmt_class_id,
        rmt_classes.rmt_class_code AS rmt_class,
        ps.colour_percentage_id,
        colour_percentages.colour_percentage,
        colour_percentages.description AS colour_description,
        ps.work_order_item_id,
        fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code
      
      FROM pallet_sequences ps
      JOIN seasons ON seasons.id = ps.season_id
      JOIN farms ON farms.id = ps.farm_id
      LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
      LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
      JOIN pucs ON pucs.id = ps.puc_id
      JOIN orchards ON orchards.id = ps.orchard_id
      LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
      LEFT JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
      LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
      LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
      LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
      JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
      LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
      LEFT JOIN marketing_varieties customer_marketing_varieties ON customer_marketing_varieties.id = customer_varieties.variety_as_customer_variety_id
      LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = ps.marketing_puc_id
      LEFT JOIN registered_orchards ON registered_orchards.id = ps.marketing_orchard_id
      JOIN marks ON marks.id = ps.mark_id
      LEFT JOIN pm_marks ON pm_marks.id = ps.pm_mark_id
      JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
      JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
      JOIN grades ON grades.id = ps.grade_id
      LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
      LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
      LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
      LEFT JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
      LEFT JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
      LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
      LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
      LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
      JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
      LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
      LEFT JOIN personnel_identifiers ON personnel_identifiers.id = ps.personnel_identifier_id
      LEFT JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
      LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
      LEFT JOIN standard_product_weights ON standard_product_weights.standard_pack_id = standard_pack_codes.id AND standard_product_weights.commodity_id = commodities.id
      LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
      LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
      WHERE ps.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_pallet_sequences
      OWNER TO postgres;

    SQL

    # vw_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_sequence_flat;
      
      CREATE OR REPLACE VIEW public.vw_pallet_sequence_flat AS
        SELECT ps.id,
          ps.pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          p.location_id,
          locations.location_long_code::text AS location,
          p.shipped,
          p.in_stock,
          p.inspected,
          p.reinspected,
          p.palletized,
          p.partially_palletized,
          p.allocated,
          floor(fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at))) AS inspection_age,
          floor(fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at))) - floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS ambient_age,
          floor(fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at))) AS reinspection_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), ps.created_at)) AS pack_to_inspect_age,
          floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at))) AS inspect_to_cold_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)), COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
          p.first_cold_storage_at,
          p.first_cold_storage_at::date AS first_cold_storage_date,
          p.govt_inspection_passed,
          p.govt_first_inspection_at,
          p.govt_first_inspection_at::date AS govt_first_inspection_date,
          p.govt_reinspection_at,
          p.govt_reinspection_at::date AS govt_reinspection_date,
          p.shipped_at,
          p.shipped_at::date AS shipped_date,
          ps.created_at AS packed_at,
          ps.created_at::date AS packed_date,
          to_char(ps.created_at, 'IYYY--IW'::text) AS packed_week,
          ps.created_at,
          ps.updated_at,
          p.scrapped,
          p.scrapped_at,
          p.scrapped_at::date AS scrapped_date,
          ps.production_run_id,
          farms.farm_code AS farm,
          farm_groups.farm_group_code AS farm_group,
          production_regions.production_region_code AS production_region,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name AS target_market,
          marks.mark_code AS mark,
          pm_marks.packaging_marks,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          CASE
              WHEN pm_boms.nett_weight IS NULL THEN ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton
              ELSE ps.carton_quantity::numeric / (NULLIF(pm_boms.nett_weight, 0::numeric) / standard_product_weights.nett_weight)
          END AS std_ctns,
          ps.product_resource_allocation_id AS resource_allocation_id,
          ( SELECT array_agg(t.treatment_code) AS array_agg
             FROM pallet_sequences sq
             JOIN treatments t ON t.id = ANY (sq.treatment_ids)
             WHERE sq.id = ps.id
             GROUP BY sq.id) AS treatments,
          ps.client_size_reference AS client_size_ref,
          ps.client_product_code,
          ps.marketing_order_number AS order_number,
          seasons.season_code AS season,
          pm_subtypes.subtype_code AS pm_subtype,
          pm_types.pm_type_code AS pm_type,
          cartons_per_pallet.cartons_per_pallet AS cpp,
          pm_products.product_code AS fruit_sticker,
          pm_products_2.product_code AS fruit_sticker_2,
          p.gross_weight,
          p.gross_weight_measured_at,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          p.exit_ref,
          p.phc,
          p.stock_created_at,
          p.intake_created_at,
          p.palletized_at,
          p.palletized_at::date AS palletized_date,
          p.partially_palletized_at,
          p.allocated_at,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
          ps.verified,
          ps.verification_passed,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          ps.verification_result,
          ps.verified_at,
          pm_boms.bom_code AS bom,
          pm_boms.system_code AS pm_bom_system_code,
          ps.extended_columns,
          ps.carton_quantity,
          ps.scanned_from_carton_id AS scanned_carton,
          ps.scrapped_at AS seq_scrapped_at,
          ps.exit_ref AS seq_exit_ref,
          ps.pick_ref,
          p.carton_quantity AS pallet_carton_quantity,
          ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
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
          CASE
              WHEN p.first_cold_storage_at IS NULL THEN false
              ELSE true
          END AS cooled,
          pol_ports.port_code AS pol,
          pod_ports.port_code AS pod,
          destination_cities.city_name AS final_destination,
          fn_party_role_name(loads.customer_party_role_id) AS customer,
          fn_party_role_name(loads.consignee_party_role_id) AS consignee,
          fn_party_role_name(loads.final_receiver_party_role_id) AS final_receiver,
          fn_party_role_name(loads.exporter_party_role_id) AS exporter,
          fn_party_role_name(loads.billing_client_party_role_id) AS billing_client,
          loads.exporter_certificate_code,
          loads.customer_reference,
          loads.order_number AS internal_order_number,
          loads.customer_order_number,
          destination_countries.country_name AS country,
          destination_regions.destination_region_name AS region,
          pod_voyage_ports.eta,
          pod_voyage_ports.ata,
          pol_voyage_ports.etd,
          pol_voyage_ports.atd,
          COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
          COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.fruit_sticker_pm_product_id,
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
          grades.rmt_grade,
          grades.inspection_class,
          ps.sell_by_code,
          ps.product_chars,
          load_voyages.booking_reference,
          govt_inspection_pallets.govt_inspection_sheet_id,
          COALESCE(govt_inspection_sheets.inspection_point, p.edi_in_inspection_point) AS inspection_point,
          inspected_dest_country.country_name AS inspected_dest_country,
          p.last_govt_inspection_pallet_id,
          p.pallet_format_id,
          p.temp_tail,
          fn_party_role_name(load_voyages.shipper_party_role_id) AS shipper,
          p.depot_pallet,
          edi_in_transactions.file_name AS edi_in_file,
          p.edi_in_consignment_note_number,
          COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at)::date AS inspection_date,
          COALESCE(p.edi_in_consignment_note_number,
          CASE
              WHEN NOT p.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number || 'F'::text
              WHEN p.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number
              ELSE ''::text
          END) AS addendum_manifest,
          p.repacked,
          p.repacked_at,
          p.repacked_at::date AS repacked_date,
          ps.repacked_from_pallet_id,
          repacked_from_pallets.pallet_number AS repacked_from_pallet_number,
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          ps.phyto_data,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.target_customer_party_role_id,
          fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
          govt_inspection_sheets.consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons,
          palletizer_details.palletizer_identifier,
          palletizer_details.palletizer_contract_worker,
          palletizer_details.palletizer_personnel_number,
          ( SELECT count(pallet_sequences.id) AS count
            FROM pallet_sequences
            WHERE pallet_sequences.pallet_id = p.id) AS sequence_count,
          ps.marketing_puc_id,
          marketing_pucs.puc_code AS marketing_puc,
          ps.marketing_orchard_id,
          registered_orchards.orchard_code AS marketing_orchard,
          ps.gtin_code,
          ps.rmt_class_id,
          rmt_classes.rmt_class_code,
          ps.packing_specification_item_id,
          fn_packing_specification_code(ps.packing_specification_item_id) AS packing_specification_code,
          ps.tu_labour_product_id,
          tu_pm_products.product_code AS tu_labour_product,
          ps.ru_labour_product_id,
          ru_pm_products.product_code AS ru_labour_product,
          ps.fruit_sticker_ids,
          ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
            FROM pm_products t
            JOIN pallet_sequences sq ON t.id = ANY (sq.fruit_sticker_ids)
            WHERE sq.id = ps.id
            GROUP BY sq.id) AS fruit_stickers,
          ps.tu_sticker_ids,
          ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
            FROM pm_products t
            JOIN pallet_sequences sq ON t.id = ANY (sq.tu_sticker_ids)
            WHERE sq.id = ps.id
            GROUP BY sq.id) AS tu_stickers,
          CASE
              WHEN p.scrapped THEN 'warning'::text
              WHEN p.shipped THEN 'inactive'::text
              WHEN p.allocated THEN 'ready'::text
              WHEN p.in_stock THEN 'ok'::text
              WHEN p.palletized OR p.partially_palletized THEN 'inprogress'::text
              WHEN p.inspected AND NOT p.govt_inspection_passed THEN 'error'::text
              WHEN ps.verified AND NOT ps.verification_passed THEN 'error'::text
              ELSE NULL::text
          END AS colour_rule,
          pucs.gap_code,
          CASE
              WHEN target_markets.inspection_tm THEN target_markets.target_market_name
              ELSE target_market_groups.target_market_group_name
          END AS inspection_tm,
          pucs.gap_code_valid_from,
          pucs.gap_code_valid_until,
          p.batch_number,
          p.rmt_container_material_owner_id,
          CONCAT(rmt_container_material_types.container_material_type_code, ' - ', fn_party_role_name(rmt_container_material_owners.rmt_material_owner_party_role_id)) AS rmt_container_material_owner,
          ps.colour_percentage_id,
          colour_percentages.colour_percentage,
          colour_percentages.description AS colour_description,
          ps.work_order_item_id,
          fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code
          
        FROM pallets p
        JOIN pallet_sequences ps ON p.id = ps.pallet_id
        LEFT JOIN pallets repacked_from_pallets ON repacked_from_pallets.id = ps.repacked_from_pallet_id
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
        LEFT JOIN pm_marks ON pm_marks.id = ps.pm_mark_id
        JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
        JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
        LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
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
        LEFT JOIN ( SELECT pallet_sequences.pallet_id,
                string_agg(DISTINCT palletizers.identifier, ', '::text) AS palletizer_identifier,
                string_agg(DISTINCT concat(palletizer_contract_workers.first_name, '_', palletizer_contract_workers.surname), ', '::text) AS palletizer_contract_worker,
                string_agg(DISTINCT palletizer_contract_workers.personnel_number, ', '::text) AS palletizer_personnel_number
              FROM cartons
              LEFT JOIN personnel_identifiers palletizers ON palletizers.id = cartons.palletizer_identifier_id
              LEFT JOIN pallet_sequences ON pallet_sequences.id = cartons.pallet_sequence_id
              LEFT JOIN contract_workers palletizer_contract_workers ON palletizer_contract_workers.personnel_identifier_id = cartons.palletizer_identifier_id
              GROUP BY pallet_sequences.pallet_id) palletizer_details ON ps.pallet_id = palletizer_details.pallet_id
        LEFT JOIN standard_product_weights ON standard_product_weights.standard_pack_id = standard_pack_codes.id AND standard_product_weights.commodity_id = commodities.id
        LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = ps.marketing_puc_id
        LEFT JOIN registered_orchards ON registered_orchards.id = ps.marketing_orchard_id
        LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
        LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = ps.tu_labour_product_id
        LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = ps.ru_labour_product_id
        LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = p.rmt_container_material_owner_id
        LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id
        LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;
        
        ALTER TABLE public.vw_pallet_sequence_flat
        OWNER TO postgres;
    SQL

    # vw_scrapped_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;

      CREATE OR REPLACE VIEW public.vw_scrapped_pallet_sequence_flat
      AS
       SELECT ps.id,
        ps.scrapped_from_pallet_id AS pallet_id,
        ps.pallet_number,
        ps.pallet_sequence_number,
        plt_packhouses.plant_resource_code AS plt_packhouse,
        plt_lines.plant_resource_code AS plt_line,
        packhouses.plant_resource_code AS packhouse,
        lines.plant_resource_code AS line,
        p.location_id,
        locations.location_long_code::text AS location,
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
        p.govt_inspection_passed,
        p.govt_first_inspection_at,
        p.govt_reinspection_at,
        fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at)) AS reinspection_age,
        p.shipped_at,
        p.shipped_at::date AS shipped_date,
        p.created_at,
        p.scrapped,
        p.scrapped_at,
        ps.production_run_id,
        farms.farm_code AS farm,
        farm_groups.farm_group_code AS farm_group,
        production_regions.production_region_code AS production_region,
        pucs.puc_code AS puc,
        orchards.orchard_code AS orchard,
        commodities.code AS commodity,
        cultivar_groups.cultivar_group_code AS cultivar_group,
        cultivars.cultivar_name AS cultivar,
        marketing_varieties.marketing_variety_code AS marketing_variety,
        fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
        target_market_groups.target_market_group_name AS packed_tm_group,
        target_markets.target_market_name AS target_market,
        marks.mark_code AS mark,
        pm_marks.packaging_marks,
        inventory_codes.inventory_code,
        cvv.marketing_variety_code AS customer_variety,
        std_fruit_size_counts.size_count_value AS std_size,
        fruit_size_references.size_reference AS size_ref,
        std_fruit_size_counts.size_count_interval_group AS count_group,
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
        pm_products_2.product_code AS fruit_sticker_2,
        p.gross_weight,
        p.gross_weight_measured_at,
        p.nett_weight,
        ps.nett_weight AS sequence_nett_weight,
        p.exit_ref,
        p.phc,
        p.stock_created_at,
        p.intake_created_at,
        p.palletized_at,
        p.palletized_at::date AS palletized_date,
        p.partially_palletized_at,
        p.allocated_at,
        pallet_bases.pallet_base_code AS pallet_base,
        pallet_stack_types.stack_type_code AS stack_type,
        fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
        ps.verified,
        ps.verification_passed,
        pallet_verification_failure_reasons.reason AS verification_failure_reason,
        ps.verification_result,
        ps.verified_at,
        pm_boms.bom_code AS bom,
        pm_boms.system_code AS pm_bom_system_code,
        ps.extended_columns,
        ps.carton_quantity,
        ps.scanned_from_carton_id AS scanned_carton,
        ps.scrapped_at AS seq_scrapped_at,
        ps.exit_ref AS seq_exit_ref,
        ps.pick_ref,
        p.carton_quantity AS pallet_carton_quantity,
        ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
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
            CASE
                WHEN p.first_cold_storage_at IS NULL THEN false
                ELSE true
            END AS cooled,
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
        p.fruit_sticker_pm_product_2_id,
        ps.pallet_verification_failure_reason_id,
        grades.grade_code AS grade,
        grades.rmt_grade,
        grades.inspection_class,
        ps.sell_by_code,
        ps.product_chars,
        p.pallet_format_id,
        ps.created_by,
        ps.verified_by,
        fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
        ps.target_customer_party_role_id,
        fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
            CASE
                WHEN p.scrapped THEN 'warning'::text
                ELSE NULL::text
            END AS colour_rule,
        p.repacked,
        p.repacked_at,
        ps.repacked_from_pallet_id,
        repacked_from_pallets.pallet_number AS repacked_from_pallet_number,
        ( SELECT ps_1.pallet_id AS repacked_to_pallet_id
               FROM pallet_sequences ps_1
                 JOIN pallets repacked_to_pallets_1 ON repacked_to_pallets_1.id = ps_1.repacked_from_pallet_id
              WHERE repacked_to_pallets_1.id = ps.scrapped_from_pallet_id
             LIMIT 1) AS repacked_to_pallet_id,
        ( SELECT ps_1.pallet_number AS repacked_to_pallet_number
               FROM pallet_sequences ps_1
                 JOIN pallets repacked_to_pallets_1 ON repacked_to_pallets_1.id = ps_1.repacked_from_pallet_id
              WHERE repacked_to_pallets_1.id = ps.scrapped_from_pallet_id
             LIMIT 1) AS repacked_to_pallet_number,
        scrap_reasons.scrap_reason,
        reworks_runs.remarks AS scrapped_remarks,
        reworks_runs."user" AS scrapped_by,
        govt_inspection_sheets.consignment_note_number,
        'DN'::text || loads.id::text AS dispatch_note,
        depots.depot_code AS depot,
        loads.edi_file_name AS po_file_name,
        palletizing_bays.plant_resource_code AS palletizing_bay,
        p.has_individual_cartons,
            CASE
                WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                ELSE target_market_groups.target_market_group_name
            END AS inspection_tm,
        ps.phyto_data,
        govt_inspection_pallets.govt_inspection_sheet_id,
        p.last_govt_inspection_pallet_id,
        govt_inspection_sheets.inspection_point
       FROM pallets p
         JOIN pallet_sequences ps ON p.id = ps.scrapped_from_pallet_id
         LEFT JOIN pallets repacked_from_pallets ON repacked_from_pallets.id = ps.repacked_from_pallet_id
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
         LEFT JOIN pm_marks ON pm_marks.id = ps.pm_mark_id
         JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
         JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
         LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
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
         LEFT JOIN reworks_runs ON p.pallet_number = ANY (reworks_runs.pallets_scrapped)
         LEFT JOIN scrap_reasons ON scrap_reasons.id = reworks_runs.scrap_reason_id
         LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = p.last_govt_inspection_pallet_id
         LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
         LEFT JOIN depots ON depots.id = loads.depot_id
         ORDER BY p.pallet_number, ps.pallet_sequence_number;
        
        ALTER TABLE public.vw_pallet_sequence_flat
        OWNER TO postgres;
    SQL
  end

  down do

    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      
      DROP VIEW public.vw_pallet_sequences;

      CREATE OR REPLACE VIEW public.vw_pallet_sequences AS
        SELECT ps.id,
        ps.id AS pallet_sequence_id,
        fn_current_status('pallet_sequences'::text, ps.id) AS status,
        ps.pallet_id,
        ps.pallet_number,
        ps.pallet_sequence_number,
        ps.created_at AS packed_at,
        ps.created_at::date AS packed_date,
        date_part('week'::text, ps.created_at) AS packed_week,
        ps.production_run_id,
        ps.production_run_id AS production_run,
        ps.season_id,
        seasons.season_code AS season,
        ps.farm_id,
        farms.farm_code AS farm,
        farm_groups.farm_group_code AS farm_group,
        production_regions.production_region_code AS production_region,
        ps.puc_id,
        pucs.puc_code AS puc,
        ps.orchard_id,
        orchards.orchard_code AS orchard,
        commodities.id AS commodity_id,
        commodities.code AS commodity,
        ps.cultivar_group_id,
        cultivar_groups.cultivar_group_code AS cultivar_group,
        ps.cultivar_id,
        cultivars.cultivar_name,
        cultivars.cultivar_code AS cultivar,
        ps.product_resource_allocation_id AS resource_allocation_id,
        ps.packhouse_resource_id,
        packhouses.plant_resource_code AS packhouse,
        ps.production_line_id,
        lines.plant_resource_code AS line,
        ps.marketing_variety_id,
        marketing_varieties.marketing_variety_code AS marketing_variety,
        ps.customer_variety_id,
        customer_varieties.variety_as_customer_variety_id,
        customer_marketing_varieties.marketing_variety_code AS customer_marketing_variety,
        ps.marketing_org_party_role_id,
        fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
        ps.marketing_puc_id,
        marketing_pucs.puc_code AS marketing_puc,
        ps.marketing_orchard_id,
        registered_orchards.orchard_code AS marketing_orchard,
        ps.marketing_order_number,
        ps.std_fruit_size_count_id,
        std_fruit_size_counts.size_count_value AS standard_size,
        std_fruit_size_counts.size_count_interval_group AS count_group,
        round((ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5), 2) AS standard_count,
        ps.basic_pack_code_id AS basic_pack_id,
        basic_pack_codes.basic_pack_code AS basic_pack,
        ps.standard_pack_code_id AS standard_pack_id,
        standard_pack_codes.standard_pack_code AS standard_pack,
        ps.fruit_actual_counts_for_pack_id,
        ps.fruit_actual_counts_for_pack_id AS actual_count_id,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
        ps.fruit_size_reference_id,
        ps.fruit_size_reference_id AS size_reference_id,
        fruit_size_references.size_reference AS size_reference,
        ps.packed_tm_group_id,
        target_market_groups.target_market_group_name AS packed_tm_group,
        ps.mark_id,
        marks.mark_code AS mark,
        ps.pm_mark_id,
        pm_marks.packaging_marks,
        ps.inventory_code_id,
        ps.inventory_code_id AS inventory_id,
        inventory_codes.inventory_code,
        ps.pallet_format_id,
        pallet_formats.description AS pallet_format,
        ps.cartons_per_pallet_id,
        cartons_per_pallet.cartons_per_pallet,
        ps.pm_bom_id,
        pm_boms.bom_code,
        pm_boms.system_code,
        ps.extended_columns,
        ps.client_size_reference,
        ps.client_product_code AS client_product,
        ps.treatment_ids,
        ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
          FROM treatments
          WHERE treatments.id = ANY (ps.treatment_ids)
          GROUP BY ps.id) AS treatments,
        ps.pm_type_id,
        pm_types.pm_type_code AS pm_type,
        ps.pm_subtype_id,
        pm_subtypes.subtype_code AS pm_subtype,
        ps.carton_quantity,
        ps.scanned_from_carton_id AS scanned_carton,
        ps.scrapped_at,
        ps.exit_ref AS exit_reference,
        ps.verification_result,
        ps.pallet_verification_failure_reason_id,
        pallet_verification_failure_reasons.reason AS verification_failure_reason,
        ps.verified,
        ps.verified_by,
        ps.verified_at,
        ps.verification_passed,
        round(ps.nett_weight, 2) AS nett_weight,
        ps.pick_ref AS pick_reference,
        ps.grade_id,
        grades.grade_code AS grade,
        grades.rmt_grade,
        ps.scrapped_from_pallet_id,
        ps.removed_from_pallet,
        ps.removed_from_pallet_id,
        ps.removed_from_pallet_at,
        ps.sell_by_code,
        ps.product_chars,
        ps.depot_pallet,
        ps.personnel_identifier_id,
        personnel_identifiers.hardware_type,
        personnel_identifiers.identifier,
        ps.contract_worker_id,
        ps.repacked_at IS NOT NULL AS repacked,
        ps.repacked_at,
        ps.repacked_from_pallet_id,
        (SELECT pallets.pallet_number
         FROM pallets
         WHERE pallets.id = ps.repacked_from_pallet_id) AS repacked_from_pallet_number,
        ps.failed_otmc_results IS NOT NULL AS failed_otmc,
        ps.failed_otmc_results AS failed_otmc_result_ids,
        (SELECT array_agg(DISTINCT orchard_test_types.test_type_code ORDER BY orchard_test_types.test_type_code) AS array_agg
         FROM orchard_test_types
         WHERE orchard_test_types.id = ANY (ps.failed_otmc_results)
         GROUP BY ps.id) AS failed_otmc_results,
        ps.phyto_data,
        ps.active,
        ps.created_by,
        ps.created_at,
        ps.updated_at,
        ps.target_customer_party_role_id,
        fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
        target_markets.target_market_name AS target_market,
        ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS standard_cartons,
        ps.rmt_class_id,
        rmt_classes.rmt_class_code AS rmt_class,
        ps.colour_percentage_id,
        colour_percentages.colour_percentage,
        colour_percentages.description AS colour_description,
        ps.work_order_item_id,
        fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code
      
      FROM pallet_sequences ps
      JOIN seasons ON seasons.id = ps.season_id
      JOIN farms ON farms.id = ps.farm_id
      LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
      LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
      JOIN pucs ON pucs.id = ps.puc_id
      JOIN orchards ON orchards.id = ps.orchard_id
      LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
      LEFT JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
      LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
      LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
      LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
      JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
      LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
      LEFT JOIN marketing_varieties customer_marketing_varieties ON customer_marketing_varieties.id = customer_varieties.variety_as_customer_variety_id
      LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = ps.marketing_puc_id
      LEFT JOIN registered_orchards ON registered_orchards.id = ps.marketing_orchard_id
      JOIN marks ON marks.id = ps.mark_id
      LEFT JOIN pm_marks ON pm_marks.id = ps.pm_mark_id
      JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
      JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
      JOIN grades ON grades.id = ps.grade_id
      LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
      LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
      LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
      LEFT JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
      LEFT JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
      LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
      LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
      LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
      JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
      LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
      LEFT JOIN personnel_identifiers ON personnel_identifiers.id = ps.personnel_identifier_id
      LEFT JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
      LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
      LEFT JOIN standard_product_weights ON standard_product_weights.standard_pack_id = standard_pack_codes.id AND standard_product_weights.commodity_id = commodities.id
      LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
      LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
      WHERE ps.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_pallet_sequences
      OWNER TO postgres;

    SQL

    # vw_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_sequence_flat;
      
      CREATE OR REPLACE VIEW public.vw_pallet_sequence_flat AS
        SELECT ps.id,
          ps.pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          p.location_id,
          locations.location_long_code::text AS location,
          p.shipped,
          p.in_stock,
          p.inspected,
          p.reinspected,
          p.palletized,
          p.partially_palletized,
          p.allocated,
          floor(fn_calc_age_days(p.id, p.created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at))) AS inspection_age,
          floor(fn_calc_age_days(p.id, p.stock_created_at, COALESCE(p.shipped_at, p.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), COALESCE(p.shipped_at, p.scrapped_at))) - floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at))) AS ambient_age,
          floor(fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at))) AS reinspection_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at), ps.created_at)) AS pack_to_inspect_age,
          floor(fn_calc_age_days(p.id, p.first_cold_storage_at, COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at))) AS inspect_to_cold_age,
          floor(fn_calc_age_days(p.id, COALESCE(p.first_cold_storage_at, COALESCE(p.shipped_at, p.scrapped_at)), COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
          p.first_cold_storage_at,
          p.first_cold_storage_at::date AS first_cold_storage_date,
          p.govt_inspection_passed,
          p.govt_first_inspection_at,
          p.govt_first_inspection_at::date AS govt_first_inspection_date,
          p.govt_reinspection_at,
          p.govt_reinspection_at::date AS govt_reinspection_date,
          p.shipped_at,
          p.shipped_at::date AS shipped_date,
          ps.created_at AS packed_at,
          ps.created_at::date AS packed_date,
          to_char(ps.created_at, 'IYYY--IW'::text) AS packed_week,
          ps.created_at,
          ps.updated_at,
          p.scrapped,
          p.scrapped_at,
          p.scrapped_at::date AS scrapped_date,
          ps.production_run_id,
          farms.farm_code AS farm,
          farm_groups.farm_group_code AS farm_group,
          production_regions.production_region_code AS production_region,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name AS target_market,
          marks.mark_code AS mark,
          pm_marks.packaging_marks,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          CASE
              WHEN pm_boms.nett_weight IS NULL THEN ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton
              ELSE ps.carton_quantity::numeric / (NULLIF(pm_boms.nett_weight, 0::numeric) / standard_product_weights.nett_weight)
          END AS std_ctns,
          ps.product_resource_allocation_id AS resource_allocation_id,
          ( SELECT array_agg(t.treatment_code) AS array_agg
             FROM pallet_sequences sq
             JOIN treatments t ON t.id = ANY (sq.treatment_ids)
             WHERE sq.id = ps.id
             GROUP BY sq.id) AS treatments,
          ps.client_size_reference AS client_size_ref,
          ps.client_product_code,
          ps.marketing_order_number AS order_number,
          seasons.season_code AS season,
          pm_subtypes.subtype_code AS pm_subtype,
          pm_types.pm_type_code AS pm_type,
          cartons_per_pallet.cartons_per_pallet AS cpp,
          pm_products.product_code AS fruit_sticker,
          pm_products_2.product_code AS fruit_sticker_2,
          p.gross_weight,
          p.gross_weight_measured_at,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          p.exit_ref,
          p.phc,
          p.stock_created_at,
          p.intake_created_at,
          p.palletized_at,
          p.palletized_at::date AS palletized_date,
          p.partially_palletized_at,
          p.allocated_at,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
          ps.verified,
          ps.verification_passed,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          ps.verification_result,
          ps.verified_at,
          pm_boms.bom_code AS bom,
          pm_boms.system_code AS pm_bom_system_code,
          ps.extended_columns,
          ps.carton_quantity,
          ps.scanned_from_carton_id AS scanned_carton,
          ps.scrapped_at AS seq_scrapped_at,
          ps.exit_ref AS seq_exit_ref,
          ps.pick_ref,
          p.carton_quantity AS pallet_carton_quantity,
          ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
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
          CASE
              WHEN p.first_cold_storage_at IS NULL THEN false
              ELSE true
          END AS cooled,
          pol_ports.port_code AS pol,
          pod_ports.port_code AS pod,
          destination_cities.city_name AS final_destination,
          fn_party_role_name(loads.customer_party_role_id) AS customer,
          fn_party_role_name(loads.consignee_party_role_id) AS consignee,
          fn_party_role_name(loads.final_receiver_party_role_id) AS final_receiver,
          fn_party_role_name(loads.exporter_party_role_id) AS exporter,
          fn_party_role_name(loads.billing_client_party_role_id) AS billing_client,
          loads.exporter_certificate_code,
          loads.customer_reference,
          loads.order_number AS internal_order_number,
          loads.customer_order_number,
          destination_countries.country_name AS country,
          destination_regions.destination_region_name AS region,
          pod_voyage_ports.eta,
          pod_voyage_ports.ata,
          pol_voyage_ports.etd,
          pol_voyage_ports.atd,
          COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
          COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.fruit_sticker_pm_product_id,
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
          grades.rmt_grade,
          ps.sell_by_code,
          ps.product_chars,
          load_voyages.booking_reference,
          govt_inspection_pallets.govt_inspection_sheet_id,
          COALESCE(govt_inspection_sheets.inspection_point, p.edi_in_inspection_point) AS inspection_point,
          inspected_dest_country.country_name AS inspected_dest_country,
          p.last_govt_inspection_pallet_id,
          p.pallet_format_id,
          p.temp_tail,
          fn_party_role_name(load_voyages.shipper_party_role_id) AS shipper,
          p.depot_pallet,
          edi_in_transactions.file_name AS edi_in_file,
          p.edi_in_consignment_note_number,
          COALESCE(p.govt_reinspection_at, p.govt_first_inspection_at)::date AS inspection_date,
          COALESCE(p.edi_in_consignment_note_number,
          CASE
              WHEN NOT p.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number || 'F'::text
              WHEN p.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number
              ELSE ''::text
          END) AS addendum_manifest,
          p.repacked,
          p.repacked_at,
          p.repacked_at::date AS repacked_date,
          ps.repacked_from_pallet_id,
          repacked_from_pallets.pallet_number AS repacked_from_pallet_number,
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          ps.phyto_data,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.target_customer_party_role_id,
          fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
          govt_inspection_sheets.consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons,
          palletizer_details.palletizer_identifier,
          palletizer_details.palletizer_contract_worker,
          palletizer_details.palletizer_personnel_number,
          ( SELECT count(pallet_sequences.id) AS count
            FROM pallet_sequences
            WHERE pallet_sequences.pallet_id = p.id) AS sequence_count,
          ps.marketing_puc_id,
          marketing_pucs.puc_code AS marketing_puc,
          ps.marketing_orchard_id,
          registered_orchards.orchard_code AS marketing_orchard,
          ps.gtin_code,
          ps.rmt_class_id,
          rmt_classes.rmt_class_code,
          ps.packing_specification_item_id,
          fn_packing_specification_code(ps.packing_specification_item_id) AS packing_specification_code,
          ps.tu_labour_product_id,
          tu_pm_products.product_code AS tu_labour_product,
          ps.ru_labour_product_id,
          ru_pm_products.product_code AS ru_labour_product,
          ps.fruit_sticker_ids,
          ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
            FROM pm_products t
            JOIN pallet_sequences sq ON t.id = ANY (sq.fruit_sticker_ids)
            WHERE sq.id = ps.id
            GROUP BY sq.id) AS fruit_stickers,
          ps.tu_sticker_ids,
          ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
            FROM pm_products t
            JOIN pallet_sequences sq ON t.id = ANY (sq.tu_sticker_ids)
            WHERE sq.id = ps.id
            GROUP BY sq.id) AS tu_stickers,
          CASE
              WHEN p.scrapped THEN 'warning'::text
              WHEN p.shipped THEN 'inactive'::text
              WHEN p.allocated THEN 'ready'::text
              WHEN p.in_stock THEN 'ok'::text
              WHEN p.palletized OR p.partially_palletized THEN 'inprogress'::text
              WHEN p.inspected AND NOT p.govt_inspection_passed THEN 'error'::text
              WHEN ps.verified AND NOT ps.verification_passed THEN 'error'::text
              ELSE NULL::text
          END AS colour_rule,
          pucs.gap_code,
          CASE
              WHEN target_markets.inspection_tm THEN target_markets.target_market_name
              ELSE target_market_groups.target_market_group_name
          END AS inspection_tm,
          pucs.gap_code_valid_from,
          pucs.gap_code_valid_until,
          p.batch_number,
          p.rmt_container_material_owner_id,
          CONCAT(rmt_container_material_types.container_material_type_code, ' - ', fn_party_role_name(rmt_container_material_owners.rmt_material_owner_party_role_id)) AS rmt_container_material_owner,
          ps.colour_percentage_id,
          colour_percentages.colour_percentage,
          colour_percentages.description AS colour_description,
          ps.work_order_item_id,
          fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code
          
        FROM pallets p
        JOIN pallet_sequences ps ON p.id = ps.pallet_id
        LEFT JOIN pallets repacked_from_pallets ON repacked_from_pallets.id = ps.repacked_from_pallet_id
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
        LEFT JOIN pm_marks ON pm_marks.id = ps.pm_mark_id
        JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
        JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
        LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
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
        LEFT JOIN ( SELECT pallet_sequences.pallet_id,
                string_agg(DISTINCT palletizers.identifier, ', '::text) AS palletizer_identifier,
                string_agg(DISTINCT concat(palletizer_contract_workers.first_name, '_', palletizer_contract_workers.surname), ', '::text) AS palletizer_contract_worker,
                string_agg(DISTINCT palletizer_contract_workers.personnel_number, ', '::text) AS palletizer_personnel_number
              FROM cartons
              LEFT JOIN personnel_identifiers palletizers ON palletizers.id = cartons.palletizer_identifier_id
              LEFT JOIN pallet_sequences ON pallet_sequences.id = cartons.pallet_sequence_id
              LEFT JOIN contract_workers palletizer_contract_workers ON palletizer_contract_workers.personnel_identifier_id = cartons.palletizer_identifier_id
              GROUP BY pallet_sequences.pallet_id) palletizer_details ON ps.pallet_id = palletizer_details.pallet_id
        LEFT JOIN standard_product_weights ON standard_product_weights.standard_pack_id = standard_pack_codes.id AND standard_product_weights.commodity_id = commodities.id
        LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = ps.marketing_puc_id
        LEFT JOIN registered_orchards ON registered_orchards.id = ps.marketing_orchard_id
        LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
        LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = ps.tu_labour_product_id
        LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = ps.ru_labour_product_id
        LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = p.rmt_container_material_owner_id
        LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id
        LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;
        
        ALTER TABLE public.vw_pallet_sequence_flat
        OWNER TO postgres;
    SQL

    # vw_scrapped_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;

      CREATE OR REPLACE VIEW public.vw_scrapped_pallet_sequence_flat
      AS
       SELECT ps.id,
        ps.scrapped_from_pallet_id AS pallet_id,
        ps.pallet_number,
        ps.pallet_sequence_number,
        plt_packhouses.plant_resource_code AS plt_packhouse,
        plt_lines.plant_resource_code AS plt_line,
        packhouses.plant_resource_code AS packhouse,
        lines.plant_resource_code AS line,
        p.location_id,
        locations.location_long_code::text AS location,
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
        p.govt_inspection_passed,
        p.govt_first_inspection_at,
        p.govt_reinspection_at,
        fn_calc_age_days(p.id, p.govt_reinspection_at, COALESCE(p.shipped_at, p.scrapped_at)) AS reinspection_age,
        p.shipped_at,
        p.shipped_at::date AS shipped_date,
        p.created_at,
        p.scrapped,
        p.scrapped_at,
        ps.production_run_id,
        farms.farm_code AS farm,
        farm_groups.farm_group_code AS farm_group,
        production_regions.production_region_code AS production_region,
        pucs.puc_code AS puc,
        orchards.orchard_code AS orchard,
        commodities.code AS commodity,
        cultivar_groups.cultivar_group_code AS cultivar_group,
        cultivars.cultivar_name AS cultivar,
        marketing_varieties.marketing_variety_code AS marketing_variety,
        fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
        target_market_groups.target_market_group_name AS packed_tm_group,
        target_markets.target_market_name AS target_market,
        marks.mark_code AS mark,
        pm_marks.packaging_marks,
        inventory_codes.inventory_code,
        cvv.marketing_variety_code AS customer_variety,
        std_fruit_size_counts.size_count_value AS std_size,
        fruit_size_references.size_reference AS size_ref,
        std_fruit_size_counts.size_count_interval_group AS count_group,
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
        pm_products_2.product_code AS fruit_sticker_2,
        p.gross_weight,
        p.gross_weight_measured_at,
        p.nett_weight,
        ps.nett_weight AS sequence_nett_weight,
        p.exit_ref,
        p.phc,
        p.stock_created_at,
        p.intake_created_at,
        p.palletized_at,
        p.palletized_at::date AS palletized_date,
        p.partially_palletized_at,
        p.allocated_at,
        pallet_bases.pallet_base_code AS pallet_base,
        pallet_stack_types.stack_type_code AS stack_type,
        fn_pallet_verification_failed(p.id) AS pallet_verification_failed,
        ps.verified,
        ps.verification_passed,
        pallet_verification_failure_reasons.reason AS verification_failure_reason,
        ps.verification_result,
        ps.verified_at,
        pm_boms.bom_code AS bom,
        pm_boms.system_code AS pm_bom_system_code,
        ps.extended_columns,
        ps.carton_quantity,
        ps.scanned_from_carton_id AS scanned_carton,
        ps.scrapped_at AS seq_scrapped_at,
        ps.exit_ref AS seq_exit_ref,
        ps.pick_ref,
        p.carton_quantity AS pallet_carton_quantity,
        ps.carton_quantity::numeric / p.carton_quantity::numeric AS pallet_size,
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
            CASE
                WHEN p.first_cold_storage_at IS NULL THEN false
                ELSE true
            END AS cooled,
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
        p.fruit_sticker_pm_product_2_id,
        ps.pallet_verification_failure_reason_id,
        grades.grade_code AS grade,
        grades.rmt_grade,
        ps.sell_by_code,
        ps.product_chars,
        p.pallet_format_id,
        ps.created_by,
        ps.verified_by,
        fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
        ps.target_customer_party_role_id,
        fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
            CASE
                WHEN p.scrapped THEN 'warning'::text
                ELSE NULL::text
            END AS colour_rule,
        p.repacked,
        p.repacked_at,
        ps.repacked_from_pallet_id,
        repacked_from_pallets.pallet_number AS repacked_from_pallet_number,
        ( SELECT ps_1.pallet_id AS repacked_to_pallet_id
               FROM pallet_sequences ps_1
                 JOIN pallets repacked_to_pallets_1 ON repacked_to_pallets_1.id = ps_1.repacked_from_pallet_id
              WHERE repacked_to_pallets_1.id = ps.scrapped_from_pallet_id
             LIMIT 1) AS repacked_to_pallet_id,
        ( SELECT ps_1.pallet_number AS repacked_to_pallet_number
               FROM pallet_sequences ps_1
                 JOIN pallets repacked_to_pallets_1 ON repacked_to_pallets_1.id = ps_1.repacked_from_pallet_id
              WHERE repacked_to_pallets_1.id = ps.scrapped_from_pallet_id
             LIMIT 1) AS repacked_to_pallet_number,
        scrap_reasons.scrap_reason,
        reworks_runs.remarks AS scrapped_remarks,
        reworks_runs."user" AS scrapped_by,
        govt_inspection_sheets.consignment_note_number,
        'DN'::text || loads.id::text AS dispatch_note,
        depots.depot_code AS depot,
        loads.edi_file_name AS po_file_name,
        palletizing_bays.plant_resource_code AS palletizing_bay,
        p.has_individual_cartons,
            CASE
                WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                ELSE target_market_groups.target_market_group_name
            END AS inspection_tm,
        ps.phyto_data,
        govt_inspection_pallets.govt_inspection_sheet_id,
        p.last_govt_inspection_pallet_id,
        govt_inspection_sheets.inspection_point
       FROM pallets p
         JOIN pallet_sequences ps ON p.id = ps.scrapped_from_pallet_id
         LEFT JOIN pallets repacked_from_pallets ON repacked_from_pallets.id = ps.repacked_from_pallet_id
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
         LEFT JOIN pm_marks ON pm_marks.id = ps.pm_mark_id
         JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
         JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
         LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
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
         LEFT JOIN reworks_runs ON p.pallet_number = ANY (reworks_runs.pallets_scrapped)
         LEFT JOIN scrap_reasons ON scrap_reasons.id = reworks_runs.scrap_reason_id
         LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = p.last_govt_inspection_pallet_id
         LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
         LEFT JOIN depots ON depots.id = loads.depot_id
         ORDER BY p.pallet_number, ps.pallet_sequence_number;
        
        ALTER TABLE public.vw_pallet_sequence_flat
        OWNER TO postgres;
    SQL
  end
end
