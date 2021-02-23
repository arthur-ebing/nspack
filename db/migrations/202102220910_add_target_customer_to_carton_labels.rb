Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_column :target_customer_party_role_id, :Integer
    end

    alter_table(:pallet_sequences) do
      add_column :target_customer_party_role_id, :Integer
    end

    # Pallet Label
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_label;
      CREATE VIEW public.vw_pallet_label AS
       SELECT pallet_sequences.id,
          pallet_sequences.pallet_id,
          pallet_sequences.pallet_sequence_number,
          farms.farm_code,
          orchards.orchard_code,
          to_char(pallet_sequences.verified_at, 'YYYY-mm-dd'::text) AS pack_date,
          date_part('week'::text, pallet_sequences.verified_at)::integer AS pack_week,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          pallet_sequences.production_run_id,
          fn_production_run_code(pallet_sequences.production_run_id) AS production_run_code,
          grades.grade_code,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          std_fruit_size_counts.size_count_value,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          inventory_codes.inventory_code,
          pallets.gross_weight::numeric(12,2) AS gross_weight,
          pallets.nett_weight::numeric(12,2) AS nett_weight,
          pallets.carton_quantity,
          basic_pack_codes.basic_pack_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          marks.mark_code,
          pallets.pallet_number,
          pallets.phc,
          pallet_sequences.pick_ref,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
          CASE WHEN target_markets.inspection_tm THEN
            target_markets.target_market_name
          ELSE
            target_market_groups.target_market_group_name
          END AS inspection_tm,
          fn_party_role_name(pallet_sequences.target_customer_party_role_id) AS target_customer,
          ( SELECT string_agg(clt.treatment_code::text, ', '::text) AS str_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = pallet_sequences.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.description AS cultivar_description,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          cvv.description AS customer_variety_description,
          farm_groups.farm_group_code,
          pucs.gap_code,
          pallet_sequences.sell_by_code,
          std_fruit_size_counts.size_count_interval_group,
          pallet_sequences.product_chars

         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (( SELECT rmt_bins.farm_id
                 FROM rmt_bins
                WHERE rmt_bins.production_run_tipped_id = production_runs.id
               LIMIT 1))
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT JOIN target_markets ON target_markets.id = pallet_sequences.target_market_id
           LEFT JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = farms.id AND farm_puc_orgs.organization_id = marketing_org.id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id;

      ALTER TABLE public.vw_pallet_label
          OWNER TO postgres;
    SQL

    # vw_cartons
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_cartons;
      CREATE OR REPLACE VIEW public.vw_cartons AS
      SELECT cartons.id AS carton_id,
        carton_labels.id AS carton_label_id,
        carton_labels.production_run_id,
        carton_labels.created_at AS carton_label_created_at,
        ABS(date_part('epoch', current_timestamp - carton_labels.created_at) / 3600)::int AS label_age_hrs,
        ABS(date_part('epoch', current_timestamp - cartons.created_at) / 3600)::int AS carton_age_hrs,
        CONCAT(contract_workers.first_name, '_', contract_workers.surname) AS contract_worker,
        cartons.created_at AS carton_verified_at,
        packhouses.plant_resource_code AS packhouse,
        lines.plant_resource_code AS line,
        packpoints.plant_resource_code AS packpoint,
        palletizing_bays.plant_resource_code AS palletizing_bay,
        system_resources.system_resource_code AS print_device,
        carton_labels.label_name,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        commodities.code AS commodity_code,
        cultivar_groups.cultivar_group_code,
        cultivars.cultivar_name,
        cultivars.cultivar_code,
        marketing_varieties.marketing_variety_code,
        cvv.marketing_variety_code AS customer_variety_code,
        std_fruit_size_counts.size_count_value AS std_size,
        fruit_size_references.size_reference AS size_ref,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        basic_pack_codes.basic_pack_code,
        standard_pack_codes.standard_pack_code,
        fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
        marks.mark_code,
        pm_marks.packaging_marks,
        inventory_codes.inventory_code,
        carton_labels.product_resource_allocation_id AS resource_allocation_id,
        product_setup_templates.template_name AS product_setup_template,
        pm_boms.bom_code AS pm_bom,
        pm_boms.system_code AS pm_bom_system_code,
        ( SELECT array_agg(t.treatment_code ORDER BY t.treatment_code) AS array_agg
          FROM treatments t
          JOIN carton_labels cl ON t.id = ANY (cl.treatment_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS treatment_codes,
        carton_labels.client_size_reference AS client_size_ref,
        carton_labels.client_product_code,
        carton_labels.marketing_order_number,
        target_market_groups.target_market_group_name AS packed_tm_group,
        target_markets.target_market_name AS target_market,
        seasons.season_code,
        pm_subtypes.subtype_code,
        pm_types.pm_type_code,
        cartons_per_pallet.cartons_per_pallet,
        pm_products.product_code,
        cartons.gross_weight,
        cartons.nett_weight,
        carton_labels.pick_ref,
        cartons.pallet_sequence_id,
        COALESCE(carton_labels.pallet_number, ( SELECT pallet_sequences.pallet_number
                FROM pallet_sequences
                WHERE pallet_sequences.id = cartons.pallet_sequence_id)) AS pallet_number,
        ( SELECT pallet_sequences.pallet_sequence_number
               FROM pallet_sequences
               WHERE pallet_sequences.id = cartons.pallet_sequence_id) AS pallet_sequence_number,
        personnel_identifiers.identifier AS personnel_identifier,
        contract_workers.personnel_number,
        packing_methods.packing_method_code,
        palletizers.identifier AS palletizer_identifier,
        CONCAT(palletizer_contract_workers.first_name, '_', palletizer_contract_workers.surname) AS palletizer_contract_worker,
        palletizer_contract_workers.personnel_number AS palletizer_personnel_number,
        cartons.is_virtual,
        carton_labels.group_incentive_id,
        carton_labels.marketing_puc_id,
        marketing_pucs.puc_code AS marketing_puc,
        carton_labels.marketing_orchard_id,
        registered_orchards.orchard_code AS marketing_orchard,
        carton_labels.rmt_bin_id,
        carton_labels.dp_carton,
        carton_labels.gtin_code,
        carton_labels.rmt_class_id,
        rmt_classes.rmt_class_code,
        carton_labels.packing_specification_item_id,
        fn_packing_specification_code(carton_labels.packing_specification_item_id) AS packing_specification_code,
        carton_labels.tu_labour_product_id,
        tu_pm_products.product_code AS tu_labour_product,
        carton_labels.ru_labour_product_id,
        ru_pm_products.product_code AS ru_labour_product,
        carton_labels.fruit_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.fruit_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS fruit_stickers,
        carton_labels.tu_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.tu_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS tu_stickers,
        carton_labels.target_customer_party_role_id,
        fn_party_role_name(carton_labels.target_customer_party_role_id) AS target_customer

       FROM carton_labels
         LEFT JOIN cartons ON carton_labels.id = cartons.carton_label_id
         JOIN production_runs ON production_runs.id = carton_labels.production_run_id
         JOIN product_setup_templates ON product_setup_templates.id = production_runs.product_setup_template_id
         JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
         JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
         LEFT JOIN plant_resources packpoints ON packpoints.id = carton_labels.resource_id
         LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = cartons.palletizing_bay_resource_id
         LEFT JOIN system_resources ON packpoints.system_resource_id = system_resources.id
         JOIN farms ON farms.id = carton_labels.farm_id
         JOIN pucs ON pucs.id = carton_labels.puc_id
         JOIN orchards ON orchards.id = carton_labels.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
         LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
         JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
         LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_id
         LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
         LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = carton_labels.std_fruit_size_count_id
         LEFT JOIN fruit_size_references ON fruit_size_references.id = carton_labels.fruit_size_reference_id
         LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = carton_labels.fruit_actual_counts_for_pack_id
         JOIN basic_pack_codes ON basic_pack_codes.id = carton_labels.basic_pack_code_id
         JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
         JOIN marks ON marks.id = carton_labels.mark_id
         LEFT JOIN pm_marks ON pm_marks.id = carton_labels.pm_mark_id
         JOIN inventory_codes ON inventory_codes.id = carton_labels.inventory_code_id
         LEFT JOIN pm_boms ON pm_boms.id = carton_labels.pm_bom_id
         LEFT JOIN pm_subtypes ON pm_subtypes.id = carton_labels.pm_subtype_id
         LEFT JOIN pm_types ON pm_types.id = carton_labels.pm_type_id
         JOIN target_market_groups ON target_market_groups.id = carton_labels.packed_tm_group_id
         LEFT JOIN target_markets ON target_markets.id = carton_labels.target_market_id
         JOIN seasons ON seasons.id = carton_labels.season_id
         JOIN cartons_per_pallet ON cartons_per_pallet.id = carton_labels.cartons_per_pallet_id
         LEFT JOIN pm_products ON pm_products.id = carton_labels.fruit_sticker_pm_product_id
         JOIN pallet_formats ON pallet_formats.id = carton_labels.pallet_format_id
         LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id
         LEFT JOIN personnel_identifiers ON personnel_identifiers.id = carton_labels.personnel_identifier_id
         JOIN packing_methods ON packing_methods.id = carton_labels.packing_method_id
         LEFT JOIN personnel_identifiers palletizers ON palletizers.id = cartons.palletizer_identifier_id
         LEFT JOIN contract_workers palletizer_contract_workers ON palletizer_contract_workers.id = cartons.palletizer_contract_worker_id
         LEFT JOIN group_incentives ON group_incentives.id = carton_labels.group_incentive_id
         LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = carton_labels.marketing_puc_id
         LEFT JOIN registered_orchards ON registered_orchards.id = carton_labels.marketing_orchard_id
         LEFT JOIN rmt_classes ON rmt_classes.id = carton_labels.rmt_class_id
         LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = carton_labels.tu_labour_product_id
         LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = carton_labels.ru_labour_product_id;

       ALTER TABLE public.vw_cartons
        OWNER TO postgres;
    SQL

    # vw_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_sequence_flat;
      CREATE OR REPLACE VIEW public.vw_pallet_sequence_flat
       AS
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
          ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS std_ctns,
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
          p.cooled,
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
                  WHEN NOT p.govt_inspection_passed THEN fn_consignment_note_number(govt_inspection_sheets.id) || 'F'::text
                  WHEN p.govt_inspection_passed THEN fn_consignment_note_number(govt_inspection_sheets.id)
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
          lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) AS consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons,
          palletizer_details.palletizer_identifier,
          palletizer_details.palletizer_contract_worker,
          palletizer_details.palletizer_personnel_number,
          ( SELECT max(pallet_sequences.pallet_sequence_number) AS max
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
              ( CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
                END) AS inspection_tm,
              pucs.gap_code_valid_from,
              pucs.gap_code_valid_until

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
           LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
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
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;

        ALTER TABLE public.vw_pallet_sequence_flat
            OWNER TO postgres;
    SQL

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

    # vw_scrapped_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;
      CREATE OR REPLACE VIEW public.vw_scrapped_pallet_sequence_flat AS
       SELECT ps.id,
          ps.scrapped_from_pallet_id AS pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
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
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
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
          repacked_to_pallets.repacked_to_pallet_id,
          repacked_to_pallets.repacked_to_pallet_number,
          scrap_reasons.scrap_reason,
          reworks_runs.remarks AS scrapped_remarks,
          reworks_runs."user" AS scrapped_by,
          lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) AS consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons

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
           LEFT JOIN ( SELECT ps_1.pallet_id AS repacked_to_pallet_id,
                  ps_1.pallet_number AS repacked_to_pallet_number,
                  ps_1.repacked_from_pallet_id
                 FROM pallet_sequences ps_1
                   JOIN pallets repacked_to_pallets_1 ON repacked_to_pallets_1.id = ps_1.repacked_from_pallet_id) repacked_to_pallets ON repacked_to_pallets.repacked_from_pallet_id = p.id
        ORDER BY p.pallet_number, ps.pallet_sequence_number;
      
      ALTER TABLE public.vw_scrapped_pallet_sequence_flat
          OWNER TO postgres;
    SQL

    # vw_pallets
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallets;
      CREATE OR REPLACE VIEW public.vw_pallets AS
       SELECT pallets.id AS pallet_id,
          fn_current_status('pallets'::text, pallets.id) AS pallet_status,
          pallets.pallet_number,
          fn_pallet_verification_failed(pallets.id) AS pallet_verification_failed,
          pallets.in_stock,
          pallets.stock_created_at,
          pallets.exit_ref,
          pallets.location_id,
          locations.location_long_code,
          pallets.pallet_format_id,
          pallet_bases.pallet_base_code,
          pallet_stack_types.stack_type_code,
          pallets.carton_quantity AS pallet_carton_quantity,
          pallets.has_individual_cartons AS individual_cartons,
          pallets.build_status,
          pallets.phc,
          pallets.intake_created_at,
          pallets.first_cold_storage_at,
          pallets.first_cold_storage_at::date AS first_cold_storage_date,
          pallets.plt_packhouse_resource_id,
          plt_packhouses.plant_resource_code AS plant_packhouse,
          pallets.plt_line_resource_id,
          plt_lines.plant_resource_code AS plant_line,
          pallets.nett_weight,
          pallets.gross_weight,
          pallets.gross_weight_measured_at,
          pallets.palletized,
          pallets.partially_palletized,
          pallets.palletized_at,
          pallets.palletized_at::date AS palletized_date,
          pallets.partially_palletized_at,
          pallets.partially_palletized_at::date AS partially_palletized_date,
          floor(fn_calc_age_days(pallets.id, pallets.created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS inspection_age,
          floor(fn_calc_age_days(pallets.id, pallets.stock_created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) - floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS ambient_age,
          floor(fn_calc_age_days(pallets.id, pallets.govt_reinspection_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS reinspection_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), pallets.created_at)) AS pack_to_inspect_age,
          floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_cold_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at)), COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
          pallets.cooled,
          pallets.temp_tail,
          pallets.depot_pallet,
          pallets.fruit_sticker_pm_product_id,
          pm_products.product_code AS fruit_sticker,
          pallets.fruit_sticker_pm_product_2_id,
          pm_products_2.product_code AS fruit_sticker_2,
          pallets.load_id,
          pallets.allocated,
          pallets.allocated_at,
          pallets.shipped,
          pallets.shipped_at,
          pallets.shipped_at::date AS shipped_date,
          pallets.inspected,
          pallets.last_govt_inspection_pallet_id,
          govt_inspection_pallets.govt_inspection_sheet_id,
          COALESCE(govt_inspection_sheets.inspection_point, pallets.edi_in_inspection_point) AS inspection_point,
          inspected_dest_country.country_name AS inspected_dest_country,
          pallets.govt_first_inspection_at,
          pallets.govt_first_inspection_at::date AS govt_first_inspection_date,
          pallets.govt_reinspection_at,
          pallets.govt_reinspection_at::date AS govt_reinspection_date,
          pallets.govt_inspection_passed,
          pallets.reinspected,
          pallets.edi_in_transaction_id,
          edi_in_transactions.file_name AS edi_in_file,
          pallets.edi_in_consignment_note_number,
          pallets.edi_in_inspection_point,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at)::date AS inspection_date,
          COALESCE(pallets.edi_in_consignment_note_number,
              CASE
                  WHEN pallets.govt_inspection_passed THEN fn_consignment_note_number(govt_inspection_sheets.id) || ''::text
                  ELSE fn_consignment_note_number(govt_inspection_sheets.id) || 'F'::text
              END) AS addendum_manifest,
          pallets.repacked AS pallet_repacked,
          pallets.repacked_at AS pallet_repacked_at,
          pallets.repacked_at::date AS pallet_repacked_date,
          pallets.scrapped,
          pallets.scrapped_at,
          pallets.scrapped_at::date AS scrapped_date,
          pallets.active,
          pallets.created_at,
          pallets.updated_at
         FROM pallets
           LEFT JOIN locations ON locations.id = pallets.location_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = pallets.fruit_sticker_pm_product_2_id
           LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
           LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
           LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
           LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = pallets.plt_packhouse_resource_id
           LEFT JOIN plant_resources plt_lines ON plt_lines.id = pallets.plt_line_resource_id
           LEFT JOIN edi_in_transactions ON edi_in_transactions.id = pallets.edi_in_transaction_id
           LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
           LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
           LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id;
      
      ALTER TABLE public.vw_pallets
          OWNER TO postgres;
    SQL

    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;

      CREATE OR REPLACE VIEW public.vw_pallet_sequences AS
       SELECT ps.id AS pallet_sequence_id,
          fn_current_status('pallet_sequences'::text, ps.id) AS sequence_status,
          ps.pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          ps.created_at AS packed_at,
          ps.created_at::date AS packed_date,
          date_part('week'::text, ps.created_at) AS packed_week,
          ps.production_run_id,
          ps.season_id,
          seasons.season_code,
          ps.farm_id,
          farms.farm_code,
          farm_groups.farm_group_code,
          production_regions.production_region_code,
          ps.puc_id,
          pucs.puc_code,
          ps.orchard_id,
          orchards.orchard_code,
          commodities.code AS commodity_code,
          ps.cultivar_group_id,
          cultivar_groups.cultivar_group_code,
          ps.cultivar_id,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          ps.product_resource_allocation_id AS resource_allocation_id,
          ps.packhouse_resource_id,
          packhouses.plant_resource_code AS packhouse_code,
          ps.production_line_id,
          lines.plant_resource_code AS line_code,
          ps.marketing_variety_id,
          marketing_varieties.marketing_variety_code,
          ps.customer_variety_id,
          customer_varieties.variety_as_customer_variety_id,
          customer_marketing_varieties.marketing_variety_code AS customer_marketing_variety_code,
          ps.std_fruit_size_count_id,
          std_fruit_size_counts.size_count_value AS standard_size,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          round((ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5), 2) AS standard_count,
          ps.basic_pack_code_id,
          basic_pack_codes.basic_pack_code,
          ps.standard_pack_code_id,
          standard_pack_codes.standard_pack_code,
          ps.fruit_actual_counts_for_pack_id,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.fruit_size_reference_id,
          fruit_size_references.size_reference AS size_ref,
          ps.marketing_org_party_role_id,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          ps.packed_tm_group_id,
          target_market_groups.target_market_group_name AS packed_tm_group,
          ps.mark_id,
          marks.mark_code AS mark,
          ps.inventory_code_id,
          inventory_codes.inventory_code,
          ps.pallet_format_id,
          pallet_formats.description AS pallet_format,
          ps.cartons_per_pallet_id,
          cartons_per_pallet.cartons_per_pallet,
          ps.pm_bom_id,
          pm_boms.bom_code,
          ps.extended_columns,
          ps.client_size_reference,
          ps.client_product_code,
          ps.treatment_ids,
          ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
                 FROM treatments
                WHERE treatments.id = ANY (ps.treatment_ids)
                GROUP BY ps.id) AS treatment_codes,
          ps.marketing_order_number,
          ps.pm_type_id,
          pm_types.pm_type_code,
          ps.pm_subtype_id,
          pm_subtypes.subtype_code,
          ps.carton_quantity AS sequence_carton_quantity,
          ps.scanned_from_carton_id AS scanned_carton,
          ps.scrapped_at AS seq_scrapped_at,
          ps.exit_ref AS seq_exit_ref,
          ps.verification_result,
          ps.pallet_verification_failure_reason_id,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          ps.verified,
          ps.verified_by,
          ps.verified_at,
          ps.verification_passed,
          round(ps.nett_weight, 2) AS sequence_nett_weight,
          ps.pick_ref,
          ps.grade_id,
          grades.grade_code,
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
          ps.repacked_at IS NOT NULL AS sequence_repacked,
          ps.repacked_at AS sequence_repacked_at,
          ps.repacked_from_pallet_id,
          ps.failed_otmc_results IS NOT NULL AS failed_otmc,
          ps.failed_otmc_results AS failed_otmc_result_ids,
          ( SELECT array_agg(DISTINCT orchard_test_types.test_type_code ORDER BY orchard_test_types.test_type_code) AS array_agg
                 FROM orchard_test_types
                WHERE orchard_test_types.id = ANY (ps.failed_otmc_results)
                GROUP BY ps.id) AS failed_otmc_results,
          ps.phyto_data,
          ps.active,
          ps.created_by,
          ps.created_at,
          ps.updated_at,
          ps.target_customer_party_role_id,
          fn_party_role_name(ps.target_customer_party_role_id) AS target_customer          

         FROM pallet_sequences ps
           JOIN seasons ON seasons.id = ps.season_id
           JOIN farms ON farms.id = ps.farm_id
           LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
           LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
           JOIN pucs ON pucs.id = ps.puc_id
           JOIN orchards ON orchards.id = ps.orchard_id
           JOIN cultivars ON cultivars.id = ps.cultivar_id
           JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
           JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
           LEFT JOIN marketing_varieties customer_marketing_varieties ON customer_marketing_varieties.id = customer_varieties.variety_as_customer_variety_id
           JOIN marks ON marks.id = ps.mark_id
           JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
           JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
           JOIN grades ON grades.id = ps.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
           LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
           LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
           LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
           LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
           LEFT JOIN personnel_identifiers ON personnel_identifiers.id = ps.personnel_identifier_id
           LEFT JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
        WHERE ps.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_pallet_sequences
          OWNER TO postgres;


      CREATE OR REPLACE VIEW public.vw_pallet_sequences_aggregated AS
       SELECT vw_pallet_sequences.pallet_id,
          vw_pallet_sequences.pallet_number,
          array_agg(DISTINCT vw_pallet_sequences.pallet_sequence_id) AS pallet_sequence_ids,
          string_agg(DISTINCT vw_pallet_sequences.sequence_status, ', '::text) AS sequence_statuses,
          string_agg(DISTINCT vw_pallet_sequences.pallet_sequence_number::text, ', '::text) AS pallet_sequence_numbers,
          string_agg(DISTINCT vw_pallet_sequences.packed_at::text, ', '::text) AS packed_at,
          string_agg(DISTINCT vw_pallet_sequences.packed_date::text, ', '::text) AS packed_dates,
          string_agg(DISTINCT vw_pallet_sequences.packed_week::text, ', '::text) AS packed_weeks,
          array_agg(DISTINCT vw_pallet_sequences.production_run_id) AS production_run_ids,
          array_agg(DISTINCT vw_pallet_sequences.season_id) AS season_ids,
          string_agg(DISTINCT vw_pallet_sequences.season_code, ', '::text) AS season_codes,
          array_agg(DISTINCT vw_pallet_sequences.farm_id) AS farm_ids,
          string_agg(DISTINCT vw_pallet_sequences.farm_code::text, ', '::text) AS farm_codes,
          string_agg(DISTINCT vw_pallet_sequences.farm_group_code::text, ', '::text) AS farm_group_codes,
          string_agg(DISTINCT vw_pallet_sequences.production_region_code, ', '::text) AS production_region_codes,
          array_agg(DISTINCT vw_pallet_sequences.puc_id) AS puc_ids,
          string_agg(DISTINCT vw_pallet_sequences.puc_code::text, ', '::text) AS puc_codes,
          array_agg(DISTINCT vw_pallet_sequences.orchard_id) AS orchard_ids,
          string_agg(DISTINCT vw_pallet_sequences.orchard_code::text, ', '::text) AS orchard_codes,
          string_agg(DISTINCT vw_pallet_sequences.commodity_code::text, ', '::text) AS commodity_codes,
          array_agg(DISTINCT vw_pallet_sequences.cultivar_group_id) AS cultivar_group_ids,
          string_agg(DISTINCT vw_pallet_sequences.cultivar_group_code, ', '::text) AS cultivar_group_codes,
          array_agg(DISTINCT vw_pallet_sequences.cultivar_id) AS cultivar_ids,
          string_agg(DISTINCT vw_pallet_sequences.cultivar_name, ', '::text) AS cultivar_names,
          string_agg(DISTINCT vw_pallet_sequences.cultivar_code, ', '::text) AS cultivar_codes,
          array_agg(DISTINCT vw_pallet_sequences.resource_allocation_id) AS resource_allocation_ids,
          array_agg(DISTINCT vw_pallet_sequences.packhouse_resource_id) AS packhouse_resource_ids,
          string_agg(DISTINCT vw_pallet_sequences.packhouse_code, ', '::text) AS packhouse_codes,
          array_agg(DISTINCT vw_pallet_sequences.production_line_id) AS production_line_ids,
          string_agg(DISTINCT vw_pallet_sequences.line_code, ', '::text) AS line_codes,
          array_agg(DISTINCT vw_pallet_sequences.marketing_variety_id) AS marketing_variety_ids,
          string_agg(DISTINCT vw_pallet_sequences.marketing_variety_code, ', '::text) AS marketing_variety_codes,
          array_agg(DISTINCT vw_pallet_sequences.customer_variety_id) AS customer_variety_ids,
          array_agg(DISTINCT vw_pallet_sequences.variety_as_customer_variety_id) AS variety_as_customer_variety_ids,
          string_agg(DISTINCT vw_pallet_sequences.customer_marketing_variety_code, ', '::text) AS customer_marketing_variety_codes,
          array_agg(DISTINCT vw_pallet_sequences.std_fruit_size_count_id) AS std_fruit_size_count_ids,
          string_agg(DISTINCT vw_pallet_sequences.standard_size::text, ', '::text) AS standard_sizes,
          string_agg(DISTINCT vw_pallet_sequences.count_group, ', '::text) AS count_groups,
          string_agg(DISTINCT vw_pallet_sequences.standard_count::text, ', '::text) AS standard_counts,
          array_agg(DISTINCT vw_pallet_sequences.basic_pack_code_id) AS basic_pack_code_ids,
          string_agg(DISTINCT vw_pallet_sequences.basic_pack_code, ', '::text) AS basic_pack_codes,
          array_agg(DISTINCT vw_pallet_sequences.standard_pack_code_id) AS standard_pack_code_ids,
          string_agg(DISTINCT vw_pallet_sequences.standard_pack_code, ', '::text) AS standard_pack_codes,
          array_agg(DISTINCT vw_pallet_sequences.fruit_actual_counts_for_pack_id) AS fruit_actual_counts_for_pack_ids,
          string_agg(DISTINCT vw_pallet_sequences.actual_count::text, ', '::text) AS actual_counts,
          string_agg(DISTINCT vw_pallet_sequences.edi_size_count, ', '::text) AS edi_size_counts,
          array_agg(DISTINCT vw_pallet_sequences.fruit_size_reference_id) AS fruit_size_reference_ids,
          string_agg(DISTINCT vw_pallet_sequences.size_ref, ', '::text) AS size_refs,
          array_agg(DISTINCT vw_pallet_sequences.marketing_org_party_role_id) AS marketing_org_party_role_ids,
          string_agg(DISTINCT vw_pallet_sequences.marketing_org, ', '::text) AS marketing_orgs,
          array_agg(DISTINCT vw_pallet_sequences.packed_tm_group_id) AS packed_tm_group_ids,
          string_agg(DISTINCT vw_pallet_sequences.packed_tm_group, ', '::text) AS packed_tm_groups,
          array_agg(DISTINCT vw_pallet_sequences.mark_id) AS mark_ids,
          string_agg(DISTINCT vw_pallet_sequences.mark, ', '::text) AS marks,
          array_agg(DISTINCT vw_pallet_sequences.inventory_code_id) AS inventory_code_ids,
          string_agg(DISTINCT vw_pallet_sequences.inventory_code, ', '::text) AS inventory_codes,
          array_agg(DISTINCT vw_pallet_sequences.pallet_format_id) AS pallet_format_ids,
          string_agg(DISTINCT vw_pallet_sequences.pallet_format, ', '::text) AS pallet_formats,
          array_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet_id) AS cartons_per_pallet_ids,
          string_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet::text, ', '::text) AS cartons_per_pallets,
          array_agg(DISTINCT vw_pallet_sequences.pm_bom_id) AS pm_bom_ids,
          string_agg(DISTINCT vw_pallet_sequences.bom_code::text, ', '::text) AS bom_codes,
          string_agg(DISTINCT vw_pallet_sequences.extended_columns::text, ', '::text) AS extended_columns,
          string_agg(DISTINCT vw_pallet_sequences.client_size_reference, ', '::text) AS client_size_references,
          string_agg(DISTINCT vw_pallet_sequences.client_product_code, ', '::text) AS client_product_codes,
          array_agg(DISTINCT treatment_id.treatment_id) AS treatment_ids,
          string_agg(DISTINCT treatment_code.treatment_code::text, ', '::text) AS treatment_codes,
          string_agg(DISTINCT vw_pallet_sequences.marketing_order_number, ', '::text) AS marketing_order_numbers,
          array_agg(DISTINCT vw_pallet_sequences.pm_type_id) AS pm_type_ids,
          string_agg(DISTINCT vw_pallet_sequences.pm_type_code::text, ', '::text) AS pm_type_codes,
          array_agg(DISTINCT vw_pallet_sequences.pm_subtype_id) AS pm_subtype_ids,
          string_agg(DISTINCT vw_pallet_sequences.subtype_code::text, ', '::text) AS subtype_codes,
          string_agg(DISTINCT vw_pallet_sequences.sequence_carton_quantity::text, ', '::text) AS sequence_carton_quantity,
          string_agg(DISTINCT vw_pallet_sequences.scanned_carton::text, ', '::text) AS scanned_cartons,
          string_agg(DISTINCT vw_pallet_sequences.seq_scrapped_at::text, ', '::text) AS seq_scrapped_at,
          string_agg(DISTINCT vw_pallet_sequences.seq_exit_ref, ', '::text) AS seq_exit_refs,
          string_agg(DISTINCT vw_pallet_sequences.verification_result, ', '::text) AS verification_results,
          array_agg(DISTINCT vw_pallet_sequences.pallet_verification_failure_reason_id) AS pallet_verification_failure_reason_ids,
          string_agg(DISTINCT vw_pallet_sequences.verification_failure_reason, ', '::text) AS verification_failure_reasons,
          bool_and(vw_pallet_sequences.verified) AS verified,
          string_agg(DISTINCT vw_pallet_sequences.verified_by, ', '::text) AS verified_by,
          string_agg(DISTINCT vw_pallet_sequences.verified_at::text, ', '::text) AS verified_at,
          bool_and(vw_pallet_sequences.verification_passed) AS verifications_passed,
          string_agg(DISTINCT vw_pallet_sequences.pick_ref, ', '::text) AS pick_refs,
          array_agg(DISTINCT vw_pallet_sequences.grade_id) AS grade_ids,
          string_agg(DISTINCT vw_pallet_sequences.grade_code, ', '::text) AS grade_codes,
          bool_and(vw_pallet_sequences.rmt_grade) AS rmt_grades,
          array_agg(DISTINCT vw_pallet_sequences.scrapped_from_pallet_id) AS scrapped_from_pallet_ids,
          bool_and(vw_pallet_sequences.removed_from_pallet) AS removed_from_pallets,
          array_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_id) AS removed_from_pallet_ids,
          string_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_at::text, ', '::text) AS removed_from_pallet_at,
          string_agg(DISTINCT vw_pallet_sequences.sell_by_code, ', '::text) AS sell_by_codes,
          string_agg(DISTINCT vw_pallet_sequences.product_chars, ', '::text) AS product_chars,
          bool_and(vw_pallet_sequences.depot_pallet) AS depot_pallets,
          array_agg(DISTINCT vw_pallet_sequences.personnel_identifier_id) AS personnel_identifier_ids,
          string_agg(DISTINCT vw_pallet_sequences.hardware_type, ', '::text) AS hardware_types,
          string_agg(DISTINCT vw_pallet_sequences.identifier, ', '::text) AS identifiers,
          array_agg(DISTINCT vw_pallet_sequences.contract_worker_id) AS contract_worker_ids,
          bool_and(vw_pallet_sequences.sequence_repacked) AS sequence_repacked,
          string_agg(DISTINCT vw_pallet_sequences.sequence_repacked_at::text, ', '::text) AS sequence_repacked_at,
          array_agg(DISTINCT vw_pallet_sequences.repacked_from_pallet_id) AS repacked_from_pallet_ids,
          bool_and(vw_pallet_sequences.failed_otmc) AS failed_otmc,
          array_agg(DISTINCT failed_otmc_result_id.failed_otmc_result_id) AS failed_otmc_result_ids,
          string_agg(DISTINCT failed_otmc_result.failed_otmc_result, ', '::text) AS failed_otmc_results,
          string_agg(DISTINCT vw_pallet_sequences.phyto_data, ', '::text) AS phyto_data,
          bool_and(vw_pallet_sequences.active) AS active,
          string_agg(DISTINCT vw_pallet_sequences.created_by, ', '::text) AS created_by,
          string_agg(DISTINCT vw_pallet_sequences.created_at::text, ', '::text) AS created_at,
          string_agg(DISTINCT vw_pallet_sequences.updated_at::text, ', '::text) AS updated_at

         FROM vw_pallet_sequences,
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.failed_otmc_result_ids <> '{}'::integer[] THEN vw_pallet_sequences.failed_otmc_result_ids
                  ELSE '{NULL}'::integer[]
              END) failed_otmc_result_id(failed_otmc_result_id),
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.failed_otmc_results <> '{}'::text[] THEN vw_pallet_sequences.failed_otmc_results
                  ELSE '{NULL}'::text[]
              END) failed_otmc_result(failed_otmc_result),
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.treatment_ids <> '{}'::integer[] THEN vw_pallet_sequences.treatment_ids
                  ELSE '{NULL}'::integer[]
              END) treatment_id(treatment_id),
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.treatment_codes <> '{}'::character varying[] THEN vw_pallet_sequences.treatment_codes
                  ELSE '{NULL}'::character varying[]
              END) treatment_code(treatment_code)
        GROUP BY vw_pallet_sequences.pallet_id, vw_pallet_sequences.pallet_number;
      
      ALTER TABLE public.vw_pallet_sequences_aggregated
          OWNER TO postgres;

    SQL

    alter_table(:pallets) do
      drop_column :target_customer_party_role_id
    end

  end

  down do
    alter_table(:pallets) do
      add_column :target_customer_party_role_id, :Integer
    end

    # Pallet Label
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_label;
      CREATE VIEW public.vw_pallet_label AS
       SELECT pallet_sequences.id,
          pallet_sequences.pallet_id,
          pallet_sequences.pallet_sequence_number,
          farms.farm_code,
          orchards.orchard_code,
          to_char(pallet_sequences.verified_at, 'YYYY-mm-dd'::text) AS pack_date,
          date_part('week'::text, pallet_sequences.verified_at)::integer AS pack_week,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          pallet_sequences.production_run_id,
          fn_production_run_code(pallet_sequences.production_run_id) AS production_run_code,
          grades.grade_code,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          std_fruit_size_counts.size_count_value,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          inventory_codes.inventory_code,
          pallets.gross_weight::numeric(12,2) AS gross_weight,
          pallets.nett_weight::numeric(12,2) AS nett_weight,
          pallets.carton_quantity,
          basic_pack_codes.basic_pack_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          marks.mark_code,
          pallets.pallet_number,
          pallets.phc,
          pallet_sequences.pick_ref,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
          CASE WHEN target_markets.inspection_tm THEN
            target_markets.target_market_name
          ELSE
            target_market_groups.target_market_group_name
          END AS inspection_tm,
          fn_party_role_name(pallets.target_customer_party_role_id) AS target_customer,
          ( SELECT string_agg(clt.treatment_code::text, ', '::text) AS str_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = pallet_sequences.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.description AS cultivar_description,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          cvv.description AS customer_variety_description,
          farm_groups.farm_group_code,
          pucs.gap_code,
          pallet_sequences.sell_by_code,
          std_fruit_size_counts.size_count_interval_group,
          pallet_sequences.product_chars

         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (( SELECT rmt_bins.farm_id
                 FROM rmt_bins
                WHERE rmt_bins.production_run_tipped_id = production_runs.id
               LIMIT 1))
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT JOIN target_markets ON target_markets.id = pallet_sequences.target_market_id
           LEFT JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = farms.id AND farm_puc_orgs.organization_id = marketing_org.id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id;

      ALTER TABLE public.vw_pallet_label
          OWNER TO postgres;
    SQL

    # vw_cartons
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_cartons;
      CREATE OR REPLACE VIEW public.vw_cartons AS
      SELECT cartons.id AS carton_id,
        carton_labels.id AS carton_label_id,
        carton_labels.production_run_id,
        carton_labels.created_at AS carton_label_created_at,
        ABS(date_part('epoch', current_timestamp - carton_labels.created_at) / 3600)::int AS label_age_hrs,
        ABS(date_part('epoch', current_timestamp - cartons.created_at) / 3600)::int AS carton_age_hrs,
        CONCAT(contract_workers.first_name, '_', contract_workers.surname) AS contract_worker,
        cartons.created_at AS carton_verified_at,
        packhouses.plant_resource_code AS packhouse,
        lines.plant_resource_code AS line,
        packpoints.plant_resource_code AS packpoint,
        palletizing_bays.plant_resource_code AS palletizing_bay,
        system_resources.system_resource_code AS print_device,
        carton_labels.label_name,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        commodities.code AS commodity_code,
        cultivar_groups.cultivar_group_code,
        cultivars.cultivar_name,
        cultivars.cultivar_code,
        marketing_varieties.marketing_variety_code,
        cvv.marketing_variety_code AS customer_variety_code,
        std_fruit_size_counts.size_count_value AS std_size,
        fruit_size_references.size_reference AS size_ref,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        basic_pack_codes.basic_pack_code,
        standard_pack_codes.standard_pack_code,
        fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
        marks.mark_code,
        pm_marks.packaging_marks,
        inventory_codes.inventory_code,
        carton_labels.product_resource_allocation_id AS resource_allocation_id,
        product_setup_templates.template_name AS product_setup_template,
        pm_boms.bom_code AS pm_bom,
        pm_boms.system_code AS pm_bom_system_code,
        ( SELECT array_agg(t.treatment_code ORDER BY t.treatment_code) AS array_agg
          FROM treatments t
          JOIN carton_labels cl ON t.id = ANY (cl.treatment_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS treatment_codes,
        carton_labels.client_size_reference AS client_size_ref,
        carton_labels.client_product_code,
        carton_labels.marketing_order_number,
        target_market_groups.target_market_group_name AS packed_tm_group,
        target_markets.target_market_name AS target_market,
        seasons.season_code,
        pm_subtypes.subtype_code,
        pm_types.pm_type_code,
        cartons_per_pallet.cartons_per_pallet,
        pm_products.product_code,
        cartons.gross_weight,
        cartons.nett_weight,
        carton_labels.pick_ref,
        cartons.pallet_sequence_id,
        COALESCE(carton_labels.pallet_number, ( SELECT pallet_sequences.pallet_number
                FROM pallet_sequences
                WHERE pallet_sequences.id = cartons.pallet_sequence_id)) AS pallet_number,
        ( SELECT pallet_sequences.pallet_sequence_number
               FROM pallet_sequences
               WHERE pallet_sequences.id = cartons.pallet_sequence_id) AS pallet_sequence_number,
        personnel_identifiers.identifier AS personnel_identifier,
        contract_workers.personnel_number,
        packing_methods.packing_method_code,
        palletizers.identifier AS palletizer_identifier,
        CONCAT(palletizer_contract_workers.first_name, '_', palletizer_contract_workers.surname) AS palletizer_contract_worker,
        palletizer_contract_workers.personnel_number AS palletizer_personnel_number,
        cartons.is_virtual,
        carton_labels.group_incentive_id,
        carton_labels.marketing_puc_id,
        marketing_pucs.puc_code AS marketing_puc,
        carton_labels.marketing_orchard_id,
        registered_orchards.orchard_code AS marketing_orchard,
        carton_labels.rmt_bin_id,
        carton_labels.dp_carton,
        carton_labels.gtin_code,
        carton_labels.rmt_class_id,
        rmt_classes.rmt_class_code,
        carton_labels.packing_specification_item_id,
        fn_packing_specification_code(carton_labels.packing_specification_item_id) AS packing_specification_code,
        carton_labels.tu_labour_product_id,
        tu_pm_products.product_code AS tu_labour_product,
        carton_labels.ru_labour_product_id,
        ru_pm_products.product_code AS ru_labour_product,
        carton_labels.fruit_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.fruit_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS fruit_stickers,
        carton_labels.tu_sticker_ids,
        ( SELECT array_agg(t.product_code ORDER BY t.product_code) AS array_agg
          FROM pm_products t
          JOIN carton_labels cl ON t.id = ANY (cl.tu_sticker_ids)
          WHERE cl.id = carton_labels.id
          GROUP BY cl.id) AS tu_stickers

       FROM carton_labels
         LEFT JOIN cartons ON carton_labels.id = cartons.carton_label_id
         JOIN production_runs ON production_runs.id = carton_labels.production_run_id
         JOIN product_setup_templates ON product_setup_templates.id = production_runs.product_setup_template_id
         JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
         JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
         LEFT JOIN plant_resources packpoints ON packpoints.id = carton_labels.resource_id
         LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = cartons.palletizing_bay_resource_id
         LEFT JOIN system_resources ON packpoints.system_resource_id = system_resources.id
         JOIN farms ON farms.id = carton_labels.farm_id
         JOIN pucs ON pucs.id = carton_labels.puc_id
         JOIN orchards ON orchards.id = carton_labels.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
         LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
         JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
         LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_id
         LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
         LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = carton_labels.std_fruit_size_count_id
         LEFT JOIN fruit_size_references ON fruit_size_references.id = carton_labels.fruit_size_reference_id
         LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = carton_labels.fruit_actual_counts_for_pack_id
         JOIN basic_pack_codes ON basic_pack_codes.id = carton_labels.basic_pack_code_id
         JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
         JOIN marks ON marks.id = carton_labels.mark_id
         LEFT JOIN pm_marks ON pm_marks.id = carton_labels.pm_mark_id
         JOIN inventory_codes ON inventory_codes.id = carton_labels.inventory_code_id
         LEFT JOIN pm_boms ON pm_boms.id = carton_labels.pm_bom_id
         LEFT JOIN pm_subtypes ON pm_subtypes.id = carton_labels.pm_subtype_id
         LEFT JOIN pm_types ON pm_types.id = carton_labels.pm_type_id
         JOIN target_market_groups ON target_market_groups.id = carton_labels.packed_tm_group_id
         LEFT JOIN target_markets ON target_markets.id = carton_labels.target_market_id
         JOIN seasons ON seasons.id = carton_labels.season_id
         JOIN cartons_per_pallet ON cartons_per_pallet.id = carton_labels.cartons_per_pallet_id
         LEFT JOIN pm_products ON pm_products.id = carton_labels.fruit_sticker_pm_product_id
         JOIN pallet_formats ON pallet_formats.id = carton_labels.pallet_format_id
         LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id
         LEFT JOIN personnel_identifiers ON personnel_identifiers.id = carton_labels.personnel_identifier_id
         JOIN packing_methods ON packing_methods.id = carton_labels.packing_method_id
         LEFT JOIN personnel_identifiers palletizers ON palletizers.id = cartons.palletizer_identifier_id
         LEFT JOIN contract_workers palletizer_contract_workers ON palletizer_contract_workers.id = cartons.palletizer_contract_worker_id
         LEFT JOIN group_incentives ON group_incentives.id = carton_labels.group_incentive_id
         LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = carton_labels.marketing_puc_id
         LEFT JOIN registered_orchards ON registered_orchards.id = carton_labels.marketing_orchard_id
         LEFT JOIN rmt_classes ON rmt_classes.id = carton_labels.rmt_class_id
         LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = carton_labels.tu_labour_product_id
         LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = carton_labels.ru_labour_product_id;

       ALTER TABLE public.vw_cartons
        OWNER TO postgres;
    SQL

    # vw_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_sequence_flat;
      CREATE OR REPLACE VIEW public.vw_pallet_sequence_flat
       AS
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
          ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS std_ctns,
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
          p.cooled,
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
                  WHEN NOT p.govt_inspection_passed THEN fn_consignment_note_number(govt_inspection_sheets.id) || 'F'::text
                  WHEN p.govt_inspection_passed THEN fn_consignment_note_number(govt_inspection_sheets.id)
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
          p.target_customer_party_role_id,
          fn_party_role_name(p.target_customer_party_role_id) AS target_customer,
          lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) AS consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons,
          palletizer_details.palletizer_identifier,
          palletizer_details.palletizer_contract_worker,
          palletizer_details.palletizer_personnel_number,
          ( SELECT max(pallet_sequences.pallet_sequence_number) AS max
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
              ( CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
                END) AS inspection_tm,
              pucs.gap_code_valid_from,
              pucs.gap_code_valid_until

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
           LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
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
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;

        ALTER TABLE public.vw_pallet_sequence_flat
            OWNER TO postgres;
    SQL

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
          p.target_customer_party_role_id,
          fn_party_role_name(p.target_customer_party_role_id) AS target_customer,
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

    # vw_scrapped_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;
      CREATE OR REPLACE VIEW public.vw_scrapped_pallet_sequence_flat AS
       SELECT ps.id,
          ps.scrapped_from_pallet_id AS pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          plt_packhouses.plant_resource_code AS plt_packhouse,
          plt_lines.plant_resource_code AS plt_line,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
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
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
          ps.sell_by_code,
          ps.product_chars,
          p.pallet_format_id,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          p.target_customer_party_role_id,
          fn_party_role_name(p.target_customer_party_role_id) AS target_customer,
              CASE
                  WHEN p.scrapped THEN 'warning'::text
                  ELSE NULL::text
              END AS colour_rule,
          p.repacked,
          p.repacked_at,
          ps.repacked_from_pallet_id,
          repacked_from_pallets.pallet_number AS repacked_from_pallet_number,
          repacked_to_pallets.repacked_to_pallet_id,
          repacked_to_pallets.repacked_to_pallet_number,
          scrap_reasons.scrap_reason,
          reworks_runs.remarks AS scrapped_remarks,
          reworks_runs."user" AS scrapped_by,
          lpad(govt_inspection_pallets.govt_inspection_sheet_id::text, 10, '0'::text) AS consignment_note_number,
          'DN'::text || loads.id::text AS dispatch_note,
          depots.depot_code AS depot,
          loads.edi_file_name AS po_file_name,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          p.has_individual_cartons

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
           LEFT JOIN ( SELECT ps_1.pallet_id AS repacked_to_pallet_id,
                  ps_1.pallet_number AS repacked_to_pallet_number,
                  ps_1.repacked_from_pallet_id
                 FROM pallet_sequences ps_1
                   JOIN pallets repacked_to_pallets_1 ON repacked_to_pallets_1.id = ps_1.repacked_from_pallet_id) repacked_to_pallets ON repacked_to_pallets.repacked_from_pallet_id = p.id
        ORDER BY p.pallet_number, ps.pallet_sequence_number;
      
      ALTER TABLE public.vw_scrapped_pallet_sequence_flat
          OWNER TO postgres;
    SQL

    # vw_pallets
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallets;
      CREATE OR REPLACE VIEW public.vw_pallets AS
       SELECT pallets.id AS pallet_id,
          fn_current_status('pallets'::text, pallets.id) AS pallet_status,
          pallets.pallet_number,
          pallets.target_customer_party_role_id,
          fn_party_role_name(pallets.target_customer_party_role_id) AS target_customer,
          fn_pallet_verification_failed(pallets.id) AS pallet_verification_failed,
          pallets.in_stock,
          pallets.stock_created_at,
          pallets.exit_ref,
          pallets.location_id,
          locations.location_long_code,
          pallets.pallet_format_id,
          pallet_bases.pallet_base_code,
          pallet_stack_types.stack_type_code,
          pallets.carton_quantity AS pallet_carton_quantity,
          pallets.has_individual_cartons AS individual_cartons,
          pallets.build_status,
          pallets.phc,
          pallets.intake_created_at,
          pallets.first_cold_storage_at,
          pallets.first_cold_storage_at::date AS first_cold_storage_date,
          pallets.plt_packhouse_resource_id,
          plt_packhouses.plant_resource_code AS plant_packhouse,
          pallets.plt_line_resource_id,
          plt_lines.plant_resource_code AS plant_line,
          pallets.nett_weight,
          pallets.gross_weight,
          pallets.gross_weight_measured_at,
          pallets.palletized,
          pallets.partially_palletized,
          pallets.palletized_at,
          pallets.palletized_at::date AS palletized_date,
          pallets.partially_palletized_at,
          pallets.partially_palletized_at::date AS partially_palletized_date,
          floor(fn_calc_age_days(pallets.id, pallets.created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS pallet_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS inspection_age,
          floor(fn_calc_age_days(pallets.id, pallets.stock_created_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS stock_age,
          floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS cold_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), COALESCE(pallets.shipped_at, pallets.scrapped_at))) - floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS ambient_age,
          floor(fn_calc_age_days(pallets.id, pallets.govt_reinspection_at, COALESCE(pallets.shipped_at, pallets.scrapped_at))) AS reinspection_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at), pallets.created_at)) AS pack_to_inspect_age,
          floor(fn_calc_age_days(pallets.id, pallets.first_cold_storage_at, COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_cold_age,
          floor(fn_calc_age_days(pallets.id, COALESCE(pallets.first_cold_storage_at, COALESCE(pallets.shipped_at, pallets.scrapped_at)), COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at))) AS inspect_to_exit_warm_age,
          pallets.cooled,
          pallets.temp_tail,
          pallets.depot_pallet,
          pallets.fruit_sticker_pm_product_id,
          pm_products.product_code AS fruit_sticker,
          pallets.fruit_sticker_pm_product_2_id,
          pm_products_2.product_code AS fruit_sticker_2,
          pallets.load_id,
          pallets.allocated,
          pallets.allocated_at,
          pallets.shipped,
          pallets.shipped_at,
          pallets.shipped_at::date AS shipped_date,
          pallets.inspected,
          pallets.last_govt_inspection_pallet_id,
          govt_inspection_pallets.govt_inspection_sheet_id,
          COALESCE(govt_inspection_sheets.inspection_point, pallets.edi_in_inspection_point) AS inspection_point,
          inspected_dest_country.country_name AS inspected_dest_country,
          pallets.govt_first_inspection_at,
          pallets.govt_first_inspection_at::date AS govt_first_inspection_date,
          pallets.govt_reinspection_at,
          pallets.govt_reinspection_at::date AS govt_reinspection_date,
          pallets.govt_inspection_passed,
          pallets.reinspected,
          pallets.edi_in_transaction_id,
          edi_in_transactions.file_name AS edi_in_file,
          pallets.edi_in_consignment_note_number,
          pallets.edi_in_inspection_point,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at)::date AS inspection_date,
          COALESCE(pallets.edi_in_consignment_note_number,
              CASE
                  WHEN pallets.govt_inspection_passed THEN fn_consignment_note_number(govt_inspection_sheets.id) || ''::text
                  ELSE fn_consignment_note_number(govt_inspection_sheets.id) || 'F'::text
              END) AS addendum_manifest,
          pallets.repacked AS pallet_repacked,
          pallets.repacked_at AS pallet_repacked_at,
          pallets.repacked_at::date AS pallet_repacked_date,
          pallets.scrapped,
          pallets.scrapped_at,
          pallets.scrapped_at::date AS scrapped_date,
          pallets.active,
          pallets.created_at,
          pallets.updated_at
         FROM pallets
           LEFT JOIN locations ON locations.id = pallets.location_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           LEFT JOIN pm_products pm_products_2 ON pm_products_2.id = pallets.fruit_sticker_pm_product_2_id
           LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
           LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
           LEFT JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
           LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = pallets.plt_packhouse_resource_id
           LEFT JOIN plant_resources plt_lines ON plt_lines.id = pallets.plt_line_resource_id
           LEFT JOIN edi_in_transactions ON edi_in_transactions.id = pallets.edi_in_transaction_id
           LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
           LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
           LEFT JOIN destination_countries inspected_dest_country ON inspected_dest_country.id = govt_inspection_sheets.destination_country_id;
      
      ALTER TABLE public.vw_pallets
          OWNER TO postgres;
    SQL

    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;

      CREATE OR REPLACE VIEW public.vw_pallet_sequences AS
       SELECT ps.id AS pallet_sequence_id,
          fn_current_status('pallet_sequences'::text, ps.id) AS sequence_status,
          ps.pallet_id,
          ps.pallet_number,
          ps.pallet_sequence_number,
          ps.created_at AS packed_at,
          ps.created_at::date AS packed_date,
          date_part('week'::text, ps.created_at) AS packed_week,
          ps.production_run_id,
          ps.season_id,
          seasons.season_code,
          ps.farm_id,
          farms.farm_code,
          farm_groups.farm_group_code,
          production_regions.production_region_code,
          ps.puc_id,
          pucs.puc_code,
          ps.orchard_id,
          orchards.orchard_code,
          commodities.code AS commodity_code,
          ps.cultivar_group_id,
          cultivar_groups.cultivar_group_code,
          ps.cultivar_id,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          ps.product_resource_allocation_id AS resource_allocation_id,
          ps.packhouse_resource_id,
          packhouses.plant_resource_code AS packhouse_code,
          ps.production_line_id,
          lines.plant_resource_code AS line_code,
          ps.marketing_variety_id,
          marketing_varieties.marketing_variety_code,
          ps.customer_variety_id,
          customer_varieties.variety_as_customer_variety_id,
          customer_marketing_varieties.marketing_variety_code AS customer_marketing_variety_code,
          ps.std_fruit_size_count_id,
          std_fruit_size_counts.size_count_value AS standard_size,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          round((ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5), 2) AS standard_count,
          ps.basic_pack_code_id,
          basic_pack_codes.basic_pack_code,
          ps.standard_pack_code_id,
          standard_pack_codes.standard_pack_code,
          ps.fruit_actual_counts_for_pack_id,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.fruit_size_reference_id,
          fruit_size_references.size_reference AS size_ref,
          ps.marketing_org_party_role_id,
          fn_party_role_name(ps.marketing_org_party_role_id) AS marketing_org,
          ps.packed_tm_group_id,
          target_market_groups.target_market_group_name AS packed_tm_group,
          ps.mark_id,
          marks.mark_code AS mark,
          ps.inventory_code_id,
          inventory_codes.inventory_code,
          ps.pallet_format_id,
          pallet_formats.description AS pallet_format,
          ps.cartons_per_pallet_id,
          cartons_per_pallet.cartons_per_pallet,
          ps.pm_bom_id,
          pm_boms.bom_code,
          ps.extended_columns,
          ps.client_size_reference,
          ps.client_product_code,
          ps.treatment_ids,
          ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
                 FROM treatments
                WHERE treatments.id = ANY (ps.treatment_ids)
                GROUP BY ps.id) AS treatment_codes,
          ps.marketing_order_number,
          ps.pm_type_id,
          pm_types.pm_type_code,
          ps.pm_subtype_id,
          pm_subtypes.subtype_code,
          ps.carton_quantity AS sequence_carton_quantity,
          ps.scanned_from_carton_id AS scanned_carton,
          ps.scrapped_at AS seq_scrapped_at,
          ps.exit_ref AS seq_exit_ref,
          ps.verification_result,
          ps.pallet_verification_failure_reason_id,
          pallet_verification_failure_reasons.reason AS verification_failure_reason,
          ps.verified,
          ps.verified_by,
          ps.verified_at,
          ps.verification_passed,
          round(ps.nett_weight, 2) AS sequence_nett_weight,
          ps.pick_ref,
          ps.grade_id,
          grades.grade_code,
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
          ps.repacked_at IS NOT NULL AS sequence_repacked,
          ps.repacked_at AS sequence_repacked_at,
          ps.repacked_from_pallet_id,
          ps.failed_otmc_results IS NOT NULL AS failed_otmc,
          ps.failed_otmc_results AS failed_otmc_result_ids,
          ( SELECT array_agg(DISTINCT orchard_test_types.test_type_code ORDER BY orchard_test_types.test_type_code) AS array_agg
                 FROM orchard_test_types
                WHERE orchard_test_types.id = ANY (ps.failed_otmc_results)
                GROUP BY ps.id) AS failed_otmc_results,
          ps.phyto_data,
          ps.active,
          ps.created_by,
          ps.created_at,
          ps.updated_at

         FROM pallet_sequences ps
           JOIN seasons ON seasons.id = ps.season_id
           JOIN farms ON farms.id = ps.farm_id
           LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
           LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
           JOIN pucs ON pucs.id = ps.puc_id
           JOIN orchards ON orchards.id = ps.orchard_id
           JOIN cultivars ON cultivars.id = ps.cultivar_id
           JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
           JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
           LEFT JOIN marketing_varieties customer_marketing_varieties ON customer_marketing_varieties.id = customer_varieties.variety_as_customer_variety_id
           JOIN marks ON marks.id = ps.mark_id
           JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
           JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
           JOIN grades ON grades.id = ps.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
           LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
           LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
           LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
           LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
           LEFT JOIN personnel_identifiers ON personnel_identifiers.id = ps.personnel_identifier_id
           LEFT JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
        WHERE ps.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_pallet_sequences
          OWNER TO postgres;

      CREATE OR REPLACE VIEW public.vw_pallet_sequences_aggregated AS
       SELECT vw_pallet_sequences.pallet_id,
          vw_pallet_sequences.pallet_number,
          array_agg(DISTINCT vw_pallet_sequences.pallet_sequence_id) AS pallet_sequence_ids,
          string_agg(DISTINCT vw_pallet_sequences.sequence_status, ', '::text) AS sequence_statuses,
          string_agg(DISTINCT vw_pallet_sequences.pallet_sequence_number::text, ', '::text) AS pallet_sequence_numbers,
          string_agg(DISTINCT vw_pallet_sequences.packed_at::text, ', '::text) AS packed_at,
          string_agg(DISTINCT vw_pallet_sequences.packed_date::text, ', '::text) AS packed_dates,
          string_agg(DISTINCT vw_pallet_sequences.packed_week::text, ', '::text) AS packed_weeks,
          array_agg(DISTINCT vw_pallet_sequences.production_run_id) AS production_run_ids,
          array_agg(DISTINCT vw_pallet_sequences.season_id) AS season_ids,
          string_agg(DISTINCT vw_pallet_sequences.season_code, ', '::text) AS season_codes,
          array_agg(DISTINCT vw_pallet_sequences.farm_id) AS farm_ids,
          string_agg(DISTINCT vw_pallet_sequences.farm_code::text, ', '::text) AS farm_codes,
          string_agg(DISTINCT vw_pallet_sequences.farm_group_code::text, ', '::text) AS farm_group_codes,
          string_agg(DISTINCT vw_pallet_sequences.production_region_code, ', '::text) AS production_region_codes,
          array_agg(DISTINCT vw_pallet_sequences.puc_id) AS puc_ids,
          string_agg(DISTINCT vw_pallet_sequences.puc_code::text, ', '::text) AS puc_codes,
          array_agg(DISTINCT vw_pallet_sequences.orchard_id) AS orchard_ids,
          string_agg(DISTINCT vw_pallet_sequences.orchard_code::text, ', '::text) AS orchard_codes,
          string_agg(DISTINCT vw_pallet_sequences.commodity_code::text, ', '::text) AS commodity_codes,
          array_agg(DISTINCT vw_pallet_sequences.cultivar_group_id) AS cultivar_group_ids,
          string_agg(DISTINCT vw_pallet_sequences.cultivar_group_code, ', '::text) AS cultivar_group_codes,
          array_agg(DISTINCT vw_pallet_sequences.cultivar_id) AS cultivar_ids,
          string_agg(DISTINCT vw_pallet_sequences.cultivar_name, ', '::text) AS cultivar_names,
          string_agg(DISTINCT vw_pallet_sequences.cultivar_code, ', '::text) AS cultivar_codes,
          array_agg(DISTINCT vw_pallet_sequences.resource_allocation_id) AS resource_allocation_ids,
          array_agg(DISTINCT vw_pallet_sequences.packhouse_resource_id) AS packhouse_resource_ids,
          string_agg(DISTINCT vw_pallet_sequences.packhouse_code, ', '::text) AS packhouse_codes,
          array_agg(DISTINCT vw_pallet_sequences.production_line_id) AS production_line_ids,
          string_agg(DISTINCT vw_pallet_sequences.line_code, ', '::text) AS line_codes,
          array_agg(DISTINCT vw_pallet_sequences.marketing_variety_id) AS marketing_variety_ids,
          string_agg(DISTINCT vw_pallet_sequences.marketing_variety_code, ', '::text) AS marketing_variety_codes,
          array_agg(DISTINCT vw_pallet_sequences.customer_variety_id) AS customer_variety_ids,
          array_agg(DISTINCT vw_pallet_sequences.variety_as_customer_variety_id) AS variety_as_customer_variety_ids,
          string_agg(DISTINCT vw_pallet_sequences.customer_marketing_variety_code, ', '::text) AS customer_marketing_variety_codes,
          array_agg(DISTINCT vw_pallet_sequences.std_fruit_size_count_id) AS std_fruit_size_count_ids,
          string_agg(DISTINCT vw_pallet_sequences.standard_size::text, ', '::text) AS standard_sizes,
          string_agg(DISTINCT vw_pallet_sequences.count_group, ', '::text) AS count_groups,
          string_agg(DISTINCT vw_pallet_sequences.standard_count::text, ', '::text) AS standard_counts,
          array_agg(DISTINCT vw_pallet_sequences.basic_pack_code_id) AS basic_pack_code_ids,
          string_agg(DISTINCT vw_pallet_sequences.basic_pack_code, ', '::text) AS basic_pack_codes,
          array_agg(DISTINCT vw_pallet_sequences.standard_pack_code_id) AS standard_pack_code_ids,
          string_agg(DISTINCT vw_pallet_sequences.standard_pack_code, ', '::text) AS standard_pack_codes,
          array_agg(DISTINCT vw_pallet_sequences.fruit_actual_counts_for_pack_id) AS fruit_actual_counts_for_pack_ids,
          string_agg(DISTINCT vw_pallet_sequences.actual_count::text, ', '::text) AS actual_counts,
          string_agg(DISTINCT vw_pallet_sequences.edi_size_count, ', '::text) AS edi_size_counts,
          array_agg(DISTINCT vw_pallet_sequences.fruit_size_reference_id) AS fruit_size_reference_ids,
          string_agg(DISTINCT vw_pallet_sequences.size_ref, ', '::text) AS size_refs,
          array_agg(DISTINCT vw_pallet_sequences.marketing_org_party_role_id) AS marketing_org_party_role_ids,
          string_agg(DISTINCT vw_pallet_sequences.marketing_org, ', '::text) AS marketing_orgs,
          array_agg(DISTINCT vw_pallet_sequences.packed_tm_group_id) AS packed_tm_group_ids,
          string_agg(DISTINCT vw_pallet_sequences.packed_tm_group, ', '::text) AS packed_tm_groups,
          array_agg(DISTINCT vw_pallet_sequences.mark_id) AS mark_ids,
          string_agg(DISTINCT vw_pallet_sequences.mark, ', '::text) AS marks,
          array_agg(DISTINCT vw_pallet_sequences.inventory_code_id) AS inventory_code_ids,
          string_agg(DISTINCT vw_pallet_sequences.inventory_code, ', '::text) AS inventory_codes,
          array_agg(DISTINCT vw_pallet_sequences.pallet_format_id) AS pallet_format_ids,
          string_agg(DISTINCT vw_pallet_sequences.pallet_format, ', '::text) AS pallet_formats,
          array_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet_id) AS cartons_per_pallet_ids,
          string_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet::text, ', '::text) AS cartons_per_pallets,
          array_agg(DISTINCT vw_pallet_sequences.pm_bom_id) AS pm_bom_ids,
          string_agg(DISTINCT vw_pallet_sequences.bom_code::text, ', '::text) AS bom_codes,
          string_agg(DISTINCT vw_pallet_sequences.extended_columns::text, ', '::text) AS extended_columns,
          string_agg(DISTINCT vw_pallet_sequences.client_size_reference, ', '::text) AS client_size_references,
          string_agg(DISTINCT vw_pallet_sequences.client_product_code, ', '::text) AS client_product_codes,
          array_agg(DISTINCT treatment_id.treatment_id) AS treatment_ids,
          string_agg(DISTINCT treatment_code.treatment_code::text, ', '::text) AS treatment_codes,
          string_agg(DISTINCT vw_pallet_sequences.marketing_order_number, ', '::text) AS marketing_order_numbers,
          array_agg(DISTINCT vw_pallet_sequences.pm_type_id) AS pm_type_ids,
          string_agg(DISTINCT vw_pallet_sequences.pm_type_code::text, ', '::text) AS pm_type_codes,
          array_agg(DISTINCT vw_pallet_sequences.pm_subtype_id) AS pm_subtype_ids,
          string_agg(DISTINCT vw_pallet_sequences.subtype_code::text, ', '::text) AS subtype_codes,
          string_agg(DISTINCT vw_pallet_sequences.sequence_carton_quantity::text, ', '::text) AS sequence_carton_quantity,
          string_agg(DISTINCT vw_pallet_sequences.scanned_carton::text, ', '::text) AS scanned_cartons,
          string_agg(DISTINCT vw_pallet_sequences.seq_scrapped_at::text, ', '::text) AS seq_scrapped_at,
          string_agg(DISTINCT vw_pallet_sequences.seq_exit_ref, ', '::text) AS seq_exit_refs,
          string_agg(DISTINCT vw_pallet_sequences.verification_result, ', '::text) AS verification_results,
          array_agg(DISTINCT vw_pallet_sequences.pallet_verification_failure_reason_id) AS pallet_verification_failure_reason_ids,
          string_agg(DISTINCT vw_pallet_sequences.verification_failure_reason, ', '::text) AS verification_failure_reasons,
          bool_and(vw_pallet_sequences.verified) AS verified,
          string_agg(DISTINCT vw_pallet_sequences.verified_by, ', '::text) AS verified_by,
          string_agg(DISTINCT vw_pallet_sequences.verified_at::text, ', '::text) AS verified_at,
          bool_and(vw_pallet_sequences.verification_passed) AS verifications_passed,
          string_agg(DISTINCT vw_pallet_sequences.pick_ref, ', '::text) AS pick_refs,
          array_agg(DISTINCT vw_pallet_sequences.grade_id) AS grade_ids,
          string_agg(DISTINCT vw_pallet_sequences.grade_code, ', '::text) AS grade_codes,
          bool_and(vw_pallet_sequences.rmt_grade) AS rmt_grades,
          array_agg(DISTINCT vw_pallet_sequences.scrapped_from_pallet_id) AS scrapped_from_pallet_ids,
          bool_and(vw_pallet_sequences.removed_from_pallet) AS removed_from_pallets,
          array_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_id) AS removed_from_pallet_ids,
          string_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_at::text, ', '::text) AS removed_from_pallet_at,
          string_agg(DISTINCT vw_pallet_sequences.sell_by_code, ', '::text) AS sell_by_codes,
          string_agg(DISTINCT vw_pallet_sequences.product_chars, ', '::text) AS product_chars,
          bool_and(vw_pallet_sequences.depot_pallet) AS depot_pallets,
          array_agg(DISTINCT vw_pallet_sequences.personnel_identifier_id) AS personnel_identifier_ids,
          string_agg(DISTINCT vw_pallet_sequences.hardware_type, ', '::text) AS hardware_types,
          string_agg(DISTINCT vw_pallet_sequences.identifier, ', '::text) AS identifiers,
          array_agg(DISTINCT vw_pallet_sequences.contract_worker_id) AS contract_worker_ids,
          bool_and(vw_pallet_sequences.sequence_repacked) AS sequence_repacked,
          string_agg(DISTINCT vw_pallet_sequences.sequence_repacked_at::text, ', '::text) AS sequence_repacked_at,
          array_agg(DISTINCT vw_pallet_sequences.repacked_from_pallet_id) AS repacked_from_pallet_ids,
          bool_and(vw_pallet_sequences.failed_otmc) AS failed_otmc,
          array_agg(DISTINCT failed_otmc_result_id.failed_otmc_result_id) AS failed_otmc_result_ids,
          string_agg(DISTINCT failed_otmc_result.failed_otmc_result, ', '::text) AS failed_otmc_results,
          string_agg(DISTINCT vw_pallet_sequences.phyto_data, ', '::text) AS phyto_data,
          bool_and(vw_pallet_sequences.active) AS active,
          string_agg(DISTINCT vw_pallet_sequences.created_by, ', '::text) AS created_by,
          string_agg(DISTINCT vw_pallet_sequences.created_at::text, ', '::text) AS created_at,
          string_agg(DISTINCT vw_pallet_sequences.updated_at::text, ', '::text) AS updated_at

         FROM vw_pallet_sequences,
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.failed_otmc_result_ids <> '{}'::integer[] THEN vw_pallet_sequences.failed_otmc_result_ids
                  ELSE '{NULL}'::integer[]
              END) failed_otmc_result_id(failed_otmc_result_id),
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.failed_otmc_results <> '{}'::text[] THEN vw_pallet_sequences.failed_otmc_results
                  ELSE '{NULL}'::text[]
              END) failed_otmc_result(failed_otmc_result),
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.treatment_ids <> '{}'::integer[] THEN vw_pallet_sequences.treatment_ids
                  ELSE '{NULL}'::integer[]
              END) treatment_id(treatment_id),
          LATERAL unnest(
              CASE
                  WHEN vw_pallet_sequences.treatment_codes <> '{}'::character varying[] THEN vw_pallet_sequences.treatment_codes
                  ELSE '{NULL}'::character varying[]
              END) treatment_code(treatment_code)
        GROUP BY vw_pallet_sequences.pallet_id, vw_pallet_sequences.pallet_number;
      
      ALTER TABLE public.vw_pallet_sequences_aggregated
          OWNER TO postgres;
    SQL

    alter_table(:carton_labels) do
      drop_column :target_customer_party_role_id
    end

    alter_table(:pallet_sequences) do
      drop_column :target_customer_party_role_id
    end
  end
end
