Sequel.migration do
  up do
    # vw_bins
    # -------------------------------------------------------------------------
    run <<~SQL
     DROP VIEW public.vw_bins;
      CREATE OR REPLACE VIEW public.vw_bins AS
       SELECT rmt_bins.id,
          rmt_bins.rmt_delivery_id,
          rmt_bins.presort_staging_run_child_id,
          rmt_bins.tipped_in_presort_at,
          rmt_bins.staged_for_presorting_at,
          rmt_bins.presort_tip_lot_number,
          rmt_bins.mixed,
          rmt_bins.presorted,
          rmt_bins.main_presort_run_lot_number,
          rmt_bins.staged_for_presorting,
          rmt_bins.legacy_data,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_bins.season_id,
              CASE
                  WHEN rmt_bins.qty_bins = 1 THEN true
                  ELSE false
              END AS discrete_bin,
          rmt_delivery_destinations.delivery_destination_code,
          plant_resources.plant_resource_code AS packhouse,
          rmt_bins.cultivar_id,
          rmt_bins.orchard_id,
          rmt_bins.farm_id,
          rmt_bins.rmt_class_id,
          rmt_bins.rmt_container_type_id,
          rmt_bins.rmt_container_material_type_id,
          rmt_bins.cultivar_group_id,
          rmt_bins.puc_id,
          rmt_bins.exit_ref,
          rmt_bins.qty_bins,
          rmt_bins.bin_asset_number,
          rmt_bins.tipped_asset_number,
          rmt_bins.scrapped_bin_asset_number,
          locations.location_long_code,
          rmt_bins.rmt_inner_container_type_id,
          rmt_bins.rmt_inner_container_material_id,
          rmt_bins.qty_inner_bins,
          rmt_bins.production_run_rebin_id,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.active,
          rmt_bins.bin_tipped,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_deliveries.date_picked,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.bin_received_date_time,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          rmt_bins.bin_tipped_date_time,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.exit_ref_date_time,
          rmt_bins.rebin_created_at,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          rmt_bins.exit_ref IS NULL AS null_exit_ref,
          rmt_bins.avg_gross_weight,
          commodities.id AS commodity_id,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          cultivars.description AS cultivar_description,
          farm_groups.farm_group_code,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          rmt_classes.rmt_class_code,
          rmt_container_material_types.container_material_type_code,
          rmt_container_types.container_type_code,
          rmt_deliveries.truck_registration_number AS rmt_delivery_truck_registration_number,
          seasons.season_code,
          rmt_bins.location_id,
              CASE
                  WHEN rmt_bins.bin_tipped THEN 'gray'::text
                  ELSE NULL::text
              END AS colour_rule,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status,
          rmt_bins.colour_percentage_id,
          colour_percentages.colour_percentage,
          rmt_bins.actual_cold_treatment_id,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          rmt_bins.actual_ripeness_treatment_id,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment,
          rmt_bins.rmt_code_id,
          rmt_codes.rmt_code

         FROM rmt_bins
         LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
         LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
         LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id 
         LEFT JOIN farms ON farms.id = rmt_bins.farm_id
         LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
         LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
         LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
         LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
         LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
         LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
         LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
         LEFT JOIN rmt_delivery_destinations ON rmt_delivery_destinations.id = rmt_deliveries.rmt_delivery_destination_id
         LEFT JOIN locations ON locations.id = rmt_bins.location_id
         LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_tipped_id
         LEFT JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
         LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
         LEFT JOIN rmt_sizes ON rmt_sizes.id=rmt_bins.rmt_size_id
         LEFT JOIN colour_percentages ON colour_percentages.id = rmt_bins.colour_percentage_id
         LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = rmt_bins.actual_cold_treatment_id
         LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = rmt_bins.actual_ripeness_treatment_id
         LEFT JOIN rmt_codes ON rmt_codes.id = rmt_bins.rmt_code_id;

      
      ALTER TABLE public.vw_bins
          OWNER TO postgres;

    SQL

    # Carton Label label
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_carton_label_lbl;

      CREATE OR REPLACE VIEW public.vw_carton_label_lbl
      AS SELECT carton_labels.id AS carton_label_id,
          carton_labels.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          carton_labels.label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          pucs.gap_code,
          orchards.orchard_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cvv.marketing_variety_code AS customer_variety_code,
          cvv.description AS customer_variety_description,
          std_fruit_size_counts.size_count_value,
          std_fruit_size_counts.size_count_interval_group,
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
          fn_party_role_delivery_address(carton_labels.marketing_org_party_role_id) AS marketer_address,
          marks.mark_code,
          inventory_codes.inventory_code,
          product_setup_templates.template_name,
          pm_boms.bom_code,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN carton_labels cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = carton_labels.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          carton_labels.client_size_reference,
          carton_labels.client_product_code,
          carton_labels.marketing_order_number,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
              END AS inspection_tm,
          fn_party_role_name(product_resource_allocations.target_customer_party_role_id) AS target_customer,
          seasons.season_code,
          pm_subtypes.subtype_code,
          pm_types.pm_type_code,
          cartons_per_pallet.cartons_per_pallet,
          pm_products.product_code,
          carton_labels.pallet_number,
          carton_labels.sell_by_code,
          grades.grade_code,
          carton_labels.product_chars,
          carton_labels.pick_ref,
          carton_labels.phc,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          contract_workers.personnel_number,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          carton_labels.gtin_code,
          pallet_formats.description AS pallet_format_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number,
          colour_percentages.colour_percentage,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment

         FROM carton_labels
           LEFT JOIN production_runs ON production_runs.id = carton_labels.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = carton_labels.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
           JOIN farms ON farms.id = carton_labels.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = carton_labels.puc_id
           JOIN orchards ON orchards.id = carton_labels.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
           LEFT JOIN grades ON grades.id = carton_labels.grade_id
           LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = carton_labels.std_fruit_size_count_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = carton_labels.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = carton_labels.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = carton_labels.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
           JOIN marks ON marks.id = carton_labels.mark_id
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
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = carton_labels.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id
           LEFT JOIN party_roles mkt_pr ON mkt_pr.id = carton_labels.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = mkt_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = carton_labels.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = carton_labels.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = carton_labels.marketing_orchard_id
           LEFT JOIN rmt_classes ON rmt_classes.id = carton_labels.rmt_class_id
           LEFT JOIN colour_percentages ON colour_percentages.id = carton_labels.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = carton_labels.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = carton_labels.actual_ripeness_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = carton_labels.rmt_code_id;
    SQL

    # Carton Label pallet seq
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_carton_label_pseq;

      CREATE OR REPLACE VIEW public.vw_carton_label_pseq
      AS SELECT pallet_sequences.id,
          cartons.carton_label_id,
          pallet_sequences.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          carton_labels.label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          pucs.gap_code,
          orchards.orchard_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cvv.marketing_variety_code AS customer_variety_code,
          cvv.description AS customer_variety_description,
          std_fruit_size_counts.size_count_value,
          std_fruit_size_counts.size_count_interval_group,
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(pallet_sequences.marketing_org_party_role_id) AS marketer,
          fn_party_role_delivery_address(pallet_sequences.marketing_org_party_role_id) AS marketer_address,
          marks.mark_code,
          inventory_codes.inventory_code,
          product_setup_templates.template_name,
          pm_boms.bom_code,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = pallet_sequences.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          pallet_sequences.client_size_reference,
          pallet_sequences.client_product_code,
          pallet_sequences.marketing_order_number,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
              END AS inspection_tm,
          fn_party_role_name(product_resource_allocations.target_customer_party_role_id) AS target_customer,
          seasons.season_code,
          pm_subtypes.subtype_code,
          pm_types.pm_type_code,
          cartons_per_pallet.cartons_per_pallet,
          pm_products.product_code,
          pallet_sequences.pallet_number,
          pallet_sequences.sell_by_code,
          grades.grade_code,
          pallet_sequences.product_chars,
          pallet_sequences.pick_ref,
          carton_labels.phc,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          contract_workers.personnel_number,
          carton_labels.created_at::date AS packed_date,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          pallet_sequences.gtin_code,
          pallet_formats.description AS pallet_format_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number,
          colour_percentages.colour_percentage,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment

         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN cartons ON
              CASE
                  WHEN pallet_sequences.scanned_from_carton_id IS NULL THEN cartons.pallet_sequence_id = pallet_sequences.id
                  ELSE cartons.id = pallet_sequences.scanned_from_carton_id
              END
           JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
           LEFT JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = pallet_sequences.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = pallet_sequences.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           LEFT JOIN pm_boms ON pm_boms.id = pallet_sequences.pm_bom_id
           LEFT JOIN pm_subtypes ON pm_subtypes.id = pallet_sequences.pm_subtype_id
           LEFT JOIN pm_types ON pm_types.id = pallet_sequences.pm_type_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT JOIN target_markets ON target_markets.id = pallet_sequences.target_market_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = pallet_sequences.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = pallet_sequences.contract_worker_id
           LEFT JOIN party_roles mkt_pr ON mkt_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = mkt_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = pallet_sequences.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = pallet_sequences.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = pallet_sequences.marketing_orchard_id
           LEFT JOIN rmt_classes ON rmt_classes.id = pallet_sequences.rmt_class_id
           LEFT JOIN colour_percentages ON colour_percentages.id = pallet_sequences.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = pallet_sequences.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = pallet_sequences.actual_ripeness_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = pallet_sequences.rmt_code_id;
    SQL

    # Carton Label product setup
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_carton_label_pset;

      CREATE OR REPLACE VIEW public.vw_carton_label_pset
      AS SELECT product_setups.id AS carton_label_id,
          product_resource_allocations.id AS product_resource_allocation_id,
          product_resource_allocations.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          label_templates.label_template_name AS label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          pucs.gap_code,
          orchards.orchard_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cvv.marketing_variety_code AS customer_variety_code,
          cvv.description AS customer_variety_description,
          std_fruit_size_counts.size_count_value,
          std_fruit_size_counts.size_count_interval_group,
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(product_setups.marketing_org_party_role_id) AS marketer,
          fn_party_role_delivery_address(product_setups.marketing_org_party_role_id) AS marketer_address,
          marks.mark_code,
          inventory_codes.inventory_code,
          product_setup_templates.template_name,
          pm_boms.bom_code,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN product_setups cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = product_setups.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          product_setups.client_size_reference,
          product_setups.client_product_code,
          product_setups.marketing_order_number,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
              END AS inspection_tm,
          fn_party_role_name(product_resource_allocations.target_customer_party_role_id) AS target_customer,
          seasons.season_code,
          'UNK'::text AS subtype_code,
          'UNK'::text AS pm_type_code,
          cartons_per_pallet.cartons_per_pallet,
          'UNKNOWN'::text AS product_code,
          'UNKNOWN'::text AS pallet_number,
          product_setups.sell_by_code,
          grades.grade_code,
          product_setups.product_chars,
          (("substring"(to_char('now'::text::date::timestamp with time zone, 'IW'::text), '.$'::text) || date_part('dow'::text, 'now'::text::date)::text) || (packhouses.resource_properties ->> 'packhouse_no'::text)) || "substring"(to_char('now'::text::date::timestamp with time zone, 'IW'::text), '.'::text) AS pick_ref,
          COALESCE(lines.resource_properties ->> 'phc'::text, packhouses.resource_properties ->> 'phc'::text) AS phc,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          'UNK'::text AS personnel_number,
          mkt_org_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          product_setups.gtin_code,
          pallet_formats.description AS pallet_format_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number,
          colour_percentages.colour_percentage,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment

         FROM product_resource_allocations
           JOIN production_runs ON production_runs.id = product_resource_allocations.production_run_id
           JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           JOIN plant_resources packhouses ON packhouses.id = production_runs.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = production_runs.production_line_id
           LEFT JOIN label_templates ON label_templates.id = product_resource_allocations.label_template_id
           JOIN farms ON farms.id = production_runs.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = production_runs.puc_id
           LEFT JOIN orchards ON orchards.id = production_runs.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
           LEFT JOIN grades ON grades.id = product_setups.grade_id
           LEFT JOIN cultivars ON cultivars.id = production_runs.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = product_setups.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = product_setups.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = product_setups.std_fruit_size_count_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = product_setups.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = product_setups.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = product_setups.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = product_setups.standard_pack_code_id
           JOIN marks ON marks.id = product_setups.mark_id
           JOIN inventory_codes ON inventory_codes.id = product_setups.inventory_code_id
           LEFT JOIN pm_boms ON pm_boms.id = product_setups.pm_bom_id
           JOIN target_market_groups ON target_market_groups.id = product_setups.packed_tm_group_id
           LEFT JOIN target_markets ON target_markets.id = product_setups.target_market_id
           JOIN seasons ON seasons.id = production_runs.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = product_setups.cartons_per_pallet_id
           JOIN pallet_formats ON pallet_formats.id = product_setups.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = product_setups.standard_pack_code_id
           LEFT JOIN party_roles mkt_pr ON mkt_pr.id = product_setups.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = mkt_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = production_runs.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN registered_orchards ON registered_orchards.puc_code::text = mkt_org_pucs.puc_code::text AND registered_orchards.cultivar_code::text = cultivars.cultivar_code AND registered_orchards.marketing_orchard
           LEFT JOIN rmt_codes ON rmt_codes.id = production_runs.rmt_code_id
           LEFT JOIN rmt_classes ON rmt_classes.id = product_setups.rmt_class_id
           LEFT JOIN colour_percentages ON colour_percentages.id = production_runs.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = production_runs.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = production_runs.actual_ripeness_treatment_id;
    SQL

    # Pallet Label
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_label;

      CREATE OR REPLACE VIEW public.vw_pallet_label
      AS SELECT pallet_sequences.id,
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
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
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
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
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
          pallet_sequences.product_chars,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          production_runs.run_batch_number,
          rmt_codes.rmt_code AS rmt_code,
          colour_percentages.colour_percentage,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment

         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           LEFT JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (( SELECT rmt_bins.farm_id
                 FROM rmt_bins
                WHERE rmt_bins.production_run_tipped_id = production_runs.id
               LIMIT 1))
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
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
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = pallet_sequences.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = pallet_sequences.marketing_orchard_id
           LEFT JOIN rmt_codes ON rmt_codes.id = pallet_sequences.rmt_code_id
           LEFT JOIN colour_percentages ON colour_percentages.id = pallet_sequences.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = pallet_sequences.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = pallet_sequences.actual_ripeness_treatment_id;
    SQL

    # Rebin Label
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_rebin_label;

      CREATE OR REPLACE VIEW public.vw_rebin_label
      AS SELECT rmt_bins.id,
          rmt_bins.bin_asset_number,
          rmt_bins.gross_weight,
          rmt_bins.nett_weight,
          rmt_bins.production_run_rebin_id AS production_run_id,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          to_char(timezone('Africa/Johannesburg'::text, rmt_bins.created_at), 'YYYY-mm-dd HH24:MI'::text) AS created_at,
          plant_resources.plant_resource_code AS line,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_container_material_types.container_material_type_code,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number,
          colour_percentages.colour_percentage,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment

         FROM rmt_bins
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_sizes ON rmt_sizes.id = rmt_bins.rmt_size_id
           LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_rebin_id
           LEFT JOIN plant_resources ON plant_resources.id = production_runs.production_line_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN colour_percentages ON colour_percentages.id = rmt_bins.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = rmt_bins.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = rmt_bins.actual_ripeness_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = rmt_bins.rmt_code_id;

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
        fn_party_role_name(carton_labels.target_customer_party_role_id) AS target_customer,
        carton_labels.rmt_container_material_owner_id,
        CONCAT(container_material_type_code, ' - ', fn_party_role_name(rmt_material_owner_party_role_id)) AS rmt_container_material_owner,
        carton_labels.colour_percentage_id,
        colour_percentages.colour_percentage,
        carton_labels.actual_cold_treatment_id,
        actual_cold_treatments.treatment_code AS actual_cold_treatment,
        carton_labels.actual_ripeness_treatment_id,
        actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment,
        carton_labels.rmt_code_id,
        rmt_codes.rmt_code
        
       FROM carton_labels
         LEFT JOIN cartons ON carton_labels.id = cartons.carton_label_id
         LEFT JOIN production_runs ON production_runs.id = carton_labels.production_run_id
         LEFT JOIN product_setup_templates ON product_setup_templates.id = production_runs.product_setup_template_id
         LEFT JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
         LEFT JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
         LEFT JOIN plant_resources packpoints ON packpoints.id = carton_labels.resource_id
         LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = cartons.palletizing_bay_resource_id
         LEFT JOIN system_resources ON packpoints.system_resource_id = system_resources.id
         JOIN farms ON farms.id = carton_labels.farm_id
         JOIN pucs ON pucs.id = carton_labels.puc_id
         JOIN orchards ON orchards.id = carton_labels.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
         LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
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
         LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = carton_labels.ru_labour_product_id
         LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = carton_labels.rmt_container_material_owner_id
         LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id
         LEFT JOIN colour_percentages ON colour_percentages.id = carton_labels.colour_percentage_id
         LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = carton_labels.actual_cold_treatment_id
         LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = carton_labels.actual_ripeness_treatment_id
         LEFT JOIN rmt_codes ON rmt_codes.id = carton_labels.rmt_code_id;

       ALTER TABLE public.vw_cartons
        OWNER TO postgres;
    SQL

    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW vw_pallet_sequence_flat;
      DROP VIEW vw_pallet_sequences_aggregated;
      DROP VIEW vw_pallet_sequences;
      
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
        CASE
            WHEN pm_boms.nett_weight IS NULL THEN ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton
            ELSE ps.carton_quantity::numeric * (NULLIF(pm_boms.nett_weight, 0::numeric) / standard_product_weights_for_commodity.nett_weight)
        END AS standard_cartons,
        ps.rmt_class_id,
        rmt_classes.rmt_class_code AS rmt_class,
        ps.colour_percentage_id,
        colour_percentages.colour_percentage,
        colour_percentages.description AS colour_description,
        ps.work_order_item_id,
        fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code,
        ps.actual_cold_treatment_id,
        actual_cold_treatments.treatment_code AS actual_cold_treatment,
        ps.actual_ripeness_treatment_id,
        actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment,
        ps.rmt_code_id,
        rmt_codes.rmt_code
      
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
      LEFT JOIN standard_product_weights standard_product_weights_for_commodity ON standard_product_weights_for_commodity.commodity_id = commodities.id AND standard_product_weights_for_commodity.is_standard_carton       
      LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
      LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
      LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = ps.actual_cold_treatment_id
      LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = ps.actual_ripeness_treatment_id
      LEFT JOIN rmt_codes ON rmt_codes.id = ps.rmt_code_id
      WHERE ps.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_pallet_sequences
      OWNER TO postgres;

    SQL

    # vw_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
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
          production_regions.inspection_region AS production_area,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          marketing_varieties.inspection_variety,
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
          std_fruit_size_counts.marketing_size_range_mm AS diameter_range,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          pm_boms.nett_weight AS pm_bom_nett_weight, 
          standard_product_weights.ratio_to_standard_carton, 
          standard_product_weights_for_commodity.nett_weight AS standard_product_weights_for_commodity_nett_weight,
          CASE
              WHEN pm_boms.nett_weight IS NULL THEN ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton
              ELSE ps.carton_quantity::numeric * (NULLIF(pm_boms.nett_weight, 0::numeric) / standard_product_weights_for_commodity.nett_weight)
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
          COALESCE(p.gross_weight, load_containers.actual_payload / (( SELECT count(*) AS count
                 FROM pallets
                WHERE pallets.load_id = loads.id))::numeric) AS gross_weight,
          p.gross_weight_measured_at,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          COALESCE(p.gross_weight / p.carton_quantity::numeric, load_containers.actual_payload / (( SELECT sum(pallets.carton_quantity) AS sum
                 FROM pallets
                WHERE pallets.load_id = loads.id))::numeric) AS carton_gross_weight,
          ps.nett_weight / ps.carton_quantity::numeric AS carton_nett_weight,
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
          load_containers.container_seal_code,
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
          concat(rmt_container_material_types.container_material_type_code, ' - ', fn_party_role_name(rmt_container_material_owners.rmt_material_owner_party_role_id)) AS rmt_container_material_owner,
          ps.colour_percentage_id,
          colour_percentages.colour_percentage,
          colour_percentages.description AS colour_description,
          ps.work_order_item_id,
          fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code,
              CASE
                  WHEN p.gross_weight IS NULL THEN ps.nett_weight / (( SELECT sum(pallet_sequences.nett_weight) AS sum
                     FROM pallet_sequences
                    WHERE (pallet_sequences.pallet_id IN ( SELECT pallets.id
                             FROM pallets
                            WHERE pallets.load_id = loads.id)))) * load_containers.actual_payload
                  ELSE ps.carton_quantity::numeric / p.carton_quantity::numeric * p.gross_weight
              END AS sequence_gross_weight,
          p.edi_in_load_number,
          ps.actual_cold_treatment_id,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          ps.actual_ripeness_treatment_id,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment,
          ps.rmt_code_id,
          rmt_codes.rmt_code

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
           LEFT JOIN standard_product_weights standard_product_weights_for_commodity ON standard_product_weights_for_commodity.commodity_id = commodities.id AND standard_product_weights_for_commodity.is_standard_carton       
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = ps.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = ps.marketing_orchard_id
           LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
           LEFT JOIN pm_products tu_pm_products ON tu_pm_products.id = ps.tu_labour_product_id
           LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = ps.ru_labour_product_id
           LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = p.rmt_container_material_owner_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id
           LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = ps.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = ps.actual_ripeness_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = ps.rmt_code_id
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;
      
      ALTER TABLE public.vw_pallet_sequence_flat
          OWNER TO postgres;
    SQL

    # vw_pallet_sequences_aggregated
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences_aggregated
       AS
      SELECT
          vw_pallet_sequences.pallet_id,
          vw_pallet_sequences.pallet_number,
          array_agg(DISTINCT vw_pallet_sequences.pallet_sequence_id::text) AS pallet_sequence_ids,
          count(vw_pallet_sequences.pallet_sequence_id) AS count,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.status::text),NULL) AS statuses,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_sequence_number::text),NULL) AS pallet_sequence_numbers,
          array_agg(vw_pallet_sequences.nett_weight::text) AS nett_weights,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_at::text),NULL) AS packed_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_date::text),NULL) AS packed_dates,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_week::text),NULL) AS packed_weeks,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.production_run::text),NULL) AS production_runs,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.season_id::text),NULL) AS season_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.season::text),NULL) AS seasons,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.farm_id::text),NULL) AS farm_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.farm::text),NULL) AS farms,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.farm_group::text),NULL) AS farm_groups,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.production_region::text),NULL) AS production_regions,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.puc_id::text),NULL) AS puc_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.puc::text),NULL) AS pucs,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.orchard_id::text),NULL) AS orchard_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.orchard::text),NULL) AS orchards,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_id::text),NULL) AS cultivar_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.commodity::text),NULL) AS commodities,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_group_id::text),NULL) AS cultivar_group_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_group::text),NULL) AS cultivar_groups,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_id::text),NULL) AS cultivar_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_name::text),NULL) AS cultivar_names,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar::text),NULL) AS cultivars,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.resource_allocation_id::text),NULL) AS resource_allocation_ids,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.packhouse_resource_id::text),NULL) AS packhouse_resource_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packhouse::text),NULL) AS packhouses,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.production_line_id::text),NULL) AS production_line_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.line::text),NULL) AS lines,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_variety_id::text),NULL) AS marketing_variety_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_variety::text),NULL) AS marketing_varieties,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.customer_variety_id::text),NULL) AS customer_variety_ids,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.variety_as_customer_variety_id::text),NULL) AS variety_as_customer_variety_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.customer_marketing_variety::text),NULL) AS customer_marketing_varieties,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_orchard_id::text),NULL) AS marketing_orchard_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_orchard::text),NULL) AS marketing_orchards,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_puc_id::text),NULL) AS marketing_puc_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_puc::text),NULL) AS marketing_pucs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.std_fruit_size_count_id::text),NULL) AS std_fruit_size_count_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_size::text),NULL) AS standard_sizes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.count_group::text),NULL) AS count_groups,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_count::text),NULL) AS standard_counts,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.basic_pack_id::text),NULL) AS basic_pack_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.basic_pack::text),NULL) AS basic_packs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_pack_id::text),NULL) AS standard_pack_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_pack::text),NULL) AS standard_packs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.fruit_actual_counts_for_pack_id::text),NULL) AS fruit_actual_counts_for_pack_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.actual_count::text),NULL) AS actual_counts,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.edi_size_count::text),NULL) AS edi_size_counts,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.fruit_size_reference_id::text),NULL) AS fruit_size_reference_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.size_reference::text),NULL) AS size_references,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_org_party_role_id::text),NULL) AS marketing_org_party_role_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_org::text),NULL) AS marketing_orgs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_tm_group_id::text),NULL) AS packed_tm_group_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_tm_group::text),NULL) AS packed_tm_groups,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.mark_id::text),NULL) AS mark_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.mark::text),NULL) AS marks,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_mark_id::text),NULL) AS pm_mark_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packaging_marks::text),NULL) AS packaging_marks,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.inventory_code_id::text),NULL) AS inventory_code_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.inventory_code::text),NULL) AS inventory_codes,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_format_id::text),NULL) AS pallet_format_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_format::text),NULL) AS pallet_formats,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet_id::text),NULL) AS cartons_per_pallet_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet::text),NULL) AS cartons_per_pallets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_bom_id::text),NULL) AS pm_bom_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.bom_code::text),NULL) AS bom_codes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.system_code::text),NULL) AS system_codes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.extended_columns::text),NULL) AS extended_columns,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.client_size_reference::text),NULL) AS client_size_references,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.client_product::text),NULL) AS client_products,
          --array_merge_agg(DISTINCT vw_pallet_sequences.treatment_ids) AS treatment_ids,
          array_merge_agg(DISTINCT vw_pallet_sequences.treatments) AS treatments,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_order_number::text),NULL) AS marketing_order_numbers,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_type_id::text),NULL) AS pm_type_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_type::text),NULL) AS pm_types,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_subtype_id::text),NULL) AS pm_subtype_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_subtype::text),NULL) AS pm_subtypes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.carton_quantity::text),NULL) AS carton_quantities,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.scanned_carton::text),NULL) AS scanned_cartons,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.scrapped_at::text),NULL) AS scrapped_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.exit_reference::text),NULL) AS exit_references,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verification_result::text),NULL) AS verification_results,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_verification_failure_reason_id::text),NULL) AS pallet_verification_failure_reason_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verification_failure_reason::text),NULL) AS verification_failure_reasons,
          bool_and(vw_pallet_sequences.verified) AS verified,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verified_by::text),NULL) AS verified_by,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verified_at::text),NULL) AS verified_at,
          bool_and(vw_pallet_sequences.verification_passed) AS verifications_passed,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pick_reference::text),NULL) AS pick_references,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.grade_id::text),NULL) AS grade_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.grade::text),NULL) AS grades,
          bool_and(vw_pallet_sequences.rmt_grade) AS rmt_grades,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.scrapped_from_pallet_id::text),NULL) AS scrapped_from_pallet_ids,
          bool_and(vw_pallet_sequences.removed_from_pallet) AS removed_from_pallets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_id::text),NULL) AS removed_from_pallet_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_at::text),NULL) AS removed_from_pallet_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.sell_by_code::text),NULL) AS sell_by_codes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.product_chars::text),NULL) AS product_chars,
          bool_and(vw_pallet_sequences.depot_pallet) AS depot_pallets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.personnel_identifier_id::text),NULL) AS personnel_identifier_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.hardware_type::text),NULL) AS hardware_types,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.identifier::text),NULL) AS identifiers,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.contract_worker_id::text),NULL) AS contract_worker_ids,
          bool_and(vw_pallet_sequences.repacked) AS repacked,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.repacked_at::text),NULL) AS repacked_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.repacked_from_pallet_id::text),NULL) AS repacked_from_pallet_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.repacked_from_pallet_number::text),NULL) AS repacked_from_pallet_numbers,
          bool_and(vw_pallet_sequences.failed_otmc) AS failed_otmc,
          --array_merge_agg(DISTINCT vw_pallet_sequences.failed_otmc_result_ids) AS failed_otmc_result_ids,
          array_merge_agg(DISTINCT vw_pallet_sequences.failed_otmc_results) AS failed_otmc_results,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.phyto_data::text),NULL) AS phyto_data,
          bool_and(vw_pallet_sequences.active) AS active,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.created_by::text),NULL) AS created_by,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.created_at::text),NULL) AS created_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.updated_at::text),NULL) AS updated_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.target_market::text),NULL) AS target_markets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.target_customer_party_role_id),NULL) AS target_customer_party_role_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.target_customer::text),NULL) AS target_customers,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_cartons::text),NULL) AS standard_cartons,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.rmt_class::text),NULL) AS rmt_classes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.colour_percentage::text),NULL) AS colour_percentages,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.actual_ripeness_treatment::text),NULL) AS actual_ripeness_treatments,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.actual_cold_treatment::text),NULL) AS actual_cold_treatments,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.rmt_code::text),NULL) AS rmt_codes
      FROM vw_pallet_sequences
      GROUP BY vw_pallet_sequences.pallet_id, vw_pallet_sequences.pallet_number;

      ALTER TABLE public.vw_pallet_sequences_aggregated
          OWNER TO postgres;
    SQL

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
              END AS colour_rule,
          ps.colour_percentage_id,
          colour_percentages.colour_percentage,
          ps.actual_cold_treatment_id,
          actual_cold_treatments.treatment_code AS actual_cold_treatment,
          ps.actual_ripeness_treatment_id,
          actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment,
          ps.rmt_code_id,
          rmt_codes.rmt_code

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
           LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
           LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = ps.actual_cold_treatment_id
           LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = ps.actual_ripeness_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = ps.rmt_code_id
        WHERE p.repacked AND p.in_stock = false
        ORDER BY p.repacked_at DESC, p.pallet_number DESC;
      
      ALTER TABLE public.vw_repacked_pallet_sequence_flat
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
        govt_inspection_sheets.inspection_point,
        ps.colour_percentage_id,
        colour_percentages.colour_percentage,
        ps.actual_cold_treatment_id,
        actual_cold_treatments.treatment_code AS actual_cold_treatment,
        ps.actual_ripeness_treatment_id,
        actual_ripeness_treatments.treatment_code AS actual_ripeness_treatment,
        ps.rmt_code_id,
        rmt_codes.rmt_code

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
         LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
         LEFT JOIN treatments actual_cold_treatments ON actual_cold_treatments.id = ps.actual_cold_treatment_id
         LEFT JOIN treatments actual_ripeness_treatments ON actual_ripeness_treatments.id = ps.actual_ripeness_treatment_id
         LEFT JOIN rmt_codes ON rmt_codes.id = ps.rmt_code_id
         ORDER BY p.pallet_number, ps.pallet_sequence_number;
        
        ALTER TABLE public.vw_pallet_sequence_flat
        OWNER TO postgres;
    SQL

    # vw_rmt_bins_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_rmt_bins_flat;

      CREATE VIEW public.vw_rmt_bins_flat AS
       SELECT rmt_bins.id,
          COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number) AS asset_number,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status,
          rmt_bins.presort_staging_run_child_id,
          rmt_bins.tipped_in_presort_at,
          rmt_bins.staged_for_presorting_at,
          rmt_bins.presort_tip_lot_number,
          rmt_bins.mixed,
          rmt_bins.sample_bin,
          rmt_bins.presorted,
          rmt_bins.main_presort_run_lot_number,
          rmt_bins.staged_for_presorting,
          rmt_bins.qty_bins,
          rmt_bins.legacy_data,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_bins.qty_bins = 1 AS discrete_bin,
          rmt_bins.qty_inner_bins,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.weighed_manually,
          rmt_bins.active,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_bins.location_id,
          locations.location_long_code,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          plant_resources.plant_resource_code AS packhouse,
          rmt_bins.season_id,
          seasons.season_code,
          rmt_bins.farm_id,
          farm_groups.farm_group_code,
          farms.farm_code,
          rmt_bins.puc_id,
          pucs.puc_code,
          rmt_bins.orchard_id,
          orchards.orchard_code,
          rmt_bins.cultivar_group_id,
          cultivar_groups.cultivar_group_code,
          rmt_bins.cultivar_id,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          cultivars.description AS cultivar_description,
          commodities.code AS commodity_code,
          rmt_bins.rmt_class_id,
          rmt_classes.rmt_class_code,
          rmt_bins.rmt_material_owner_party_role_id,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          rmt_bins.rmt_container_type_id,
          rmt_container_types.container_type_code,
          rmt_bins.rmt_container_material_type_id,
          rmt_container_material_types.container_material_type_code,
          rmt_bins.rmt_inner_container_type_id,
          rmt_inner_container_types.container_type_code AS inner_container_type_code,
          rmt_bins.rmt_inner_container_material_id,
          rmt_inner_container_material_types.container_material_type_code AS inner_container_material_type_code,
          rmt_bins.scrapped_rmt_delivery_id,
          rmt_bins.rmt_delivery_id,
          rmt_delivery_destinations.delivery_destination_code,
          rmt_deliveries.date_picked AS picked_at,
          rmt_deliveries.truck_registration_number AS delivery_truck_registration_number,
          rmt_bins.exit_ref,
          rmt_bins.exit_ref IS NULL AS null_exit_ref,
          rmt_bins.exit_ref_date_time AS exit_ref_at,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.bin_asset_number,
          rmt_bins.bin_received_date_time AS bin_received_at,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.tipped_asset_number,
          rmt_bins.bin_tipped,
          rmt_bins.tipped_manually,
          rmt_bins.bin_tipped_date_time AS bin_tipped_at,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          date_part('week'::text, rmt_bins.bin_tipped_date_time) AS bin_tipped_week,
          rmt_bins.shipped_asset_number,
          bin_loads.shipped IS TRUE AS shipped,
          bin_loads.shipped_at,
          bin_load_products.bin_load_id,
          rmt_bins.bin_load_product_id,
          rmt_bins.scrapped_bin_asset_number,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          rmt_bins.scrap_remarks,
          rmt_bins.unscrapped_at,
          rmt_bins.production_run_rebin_id,
          rmt_bins.rebin_created_at,
          rmt_bins.avg_gross_weight,
          farm_sections.farm_section_name,
          fn_party_role_name(farm_sections.farm_manager_party_role_id) AS farm_manager,
          floor(ABS(date_part('epoch', COALESCE(rmt_bins.bin_received_date_time::timestamp, rmt_bins.created_at::timestamp) - COALESCE(rmt_bins.exit_ref_date_time::timestamp, current_timestamp)) / 86400)) AS age,
          lines.plant_resource_code AS tip_line,
          rmt_bins.coldroom_events,
          concat_ws(' ',
                    location_coldroom_events.event_name,
                    to_char (location_coldroom_events.created_at, 'YYYY-MM-DD HH24:MI:SS'),
                    cold_loc.location_long_code) AS last_coldroom_event,
          rmt_bins.rmt_classifications,
          ( SELECT array_agg(DISTINCT rmt_classifications.rmt_classification) AS array_agg
            FROM rmt_classifications
            WHERE rmt_classifications.id = ANY (rmt_bins.rmt_classifications)
            GROUP BY rmt_bins.id) AS classifications,
          rmt_bins.main_ripeness_treatment_id,
          main_ripeness_treatments.treatment_code AS main_ripeness_treatment,
          rmt_bins.main_cold_treatment_id,
          main_cold_treatments.treatment_code AS main_cold_treatment,
          rmt_bins.rmt_treatments,
          ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
            FROM treatments
            WHERE treatments.id = ANY (rmt_bins.rmt_treatments)
            GROUP BY rmt_bins.id) AS treatments,
          rmt_bins.rmt_code_id,
          rmt_codes.rmt_code,
          rmt_handling_regimes.regime_code,
          ripeness_treatments.treatment_code as actual_ripeness_treatment,
          cold_treatments.treatment_code as actual_cold_treatment,
          rmt_bins.colour_percentage_id,
          colour_percentages.colour_percentage         

         FROM rmt_bins
           LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN farm_sections ON farm_sections.id = orchards.farm_section_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
           LEFT JOIN rmt_container_material_types rmt_inner_container_material_types ON rmt_inner_container_material_types.id = rmt_bins.rmt_inner_container_material_id
           LEFT JOIN rmt_container_types rmt_inner_container_types ON rmt_inner_container_types.id = rmt_bins.rmt_inner_container_type_id
           LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
           LEFT JOIN rmt_delivery_destinations ON rmt_delivery_destinations.id = rmt_deliveries.rmt_delivery_destination_id
           LEFT JOIN locations ON locations.id = rmt_bins.location_id
           LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_tipped_id
           LEFT JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = production_runs.production_line_id
           LEFT JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
           LEFT JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
           LEFT JOIN rmt_sizes ON rmt_sizes.id=rmt_bins.rmt_size_id
           LEFT JOIN location_coldroom_events ON location_coldroom_events.id = rmt_bins.coldroom_events[array_upper(rmt_bins.coldroom_events, 1)]
           LEFT JOIN locations cold_loc ON cold_loc.id = location_coldroom_events.location_id
           LEFT JOIN treatments main_ripeness_treatments ON main_ripeness_treatments.id = rmt_bins.main_ripeness_treatment_id
           LEFT JOIN treatments main_cold_treatments ON main_cold_treatments.id = rmt_bins.main_cold_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = rmt_bins.rmt_code_id
           LEFT JOIN rmt_handling_regimes ON rmt_handling_regimes.id = rmt_codes.rmt_handling_regime_id
           LEFT JOIN treatments AS cold_treatments ON cold_treatments.id = rmt_bins.actual_cold_treatment_id
           LEFT JOIN treatments AS ripeness_treatments ON ripeness_treatments.id = rmt_bins.actual_ripeness_treatment_id
           LEFT JOIN colour_percentages ON colour_percentages.id = rmt_bins.colour_percentage_id;
      SQL
  end

  down do
    # vw_bins
    # -------------------------------------------------------------------------
    run <<~SQL
     DROP VIEW public.vw_bins;
      CREATE OR REPLACE VIEW public.vw_bins AS
       SELECT rmt_bins.id,
          rmt_bins.rmt_delivery_id,
          rmt_bins.presort_staging_run_child_id,
          rmt_bins.tipped_in_presort_at,
          rmt_bins.staged_for_presorting_at,
          rmt_bins.presort_tip_lot_number,
          rmt_bins.mixed,
          rmt_bins.presorted,
          rmt_bins.main_presort_run_lot_number,
          rmt_bins.staged_for_presorting,
          rmt_bins.legacy_data,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_bins.season_id,
              CASE
                  WHEN rmt_bins.qty_bins = 1 THEN true
                  ELSE false
              END AS discrete_bin,
          rmt_delivery_destinations.delivery_destination_code,
          plant_resources.plant_resource_code AS packhouse,
          rmt_bins.cultivar_id,
          rmt_bins.orchard_id,
          rmt_bins.farm_id,
          rmt_bins.rmt_class_id,
          rmt_bins.rmt_container_type_id,
          rmt_bins.rmt_container_material_type_id,
          rmt_bins.cultivar_group_id,
          rmt_bins.puc_id,
          rmt_bins.exit_ref,
          rmt_bins.qty_bins,
          rmt_bins.bin_asset_number,
          rmt_bins.tipped_asset_number,
          rmt_bins.scrapped_bin_asset_number,
          locations.location_long_code,
          rmt_bins.rmt_inner_container_type_id,
          rmt_bins.rmt_inner_container_material_id,
          rmt_bins.qty_inner_bins,
          rmt_bins.production_run_rebin_id,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.active,
          rmt_bins.bin_tipped,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_deliveries.date_picked,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.bin_received_date_time,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          rmt_bins.bin_tipped_date_time,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.exit_ref_date_time,
          rmt_bins.rebin_created_at,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          rmt_bins.exit_ref IS NULL AS null_exit_ref,
          rmt_bins.avg_gross_weight,
          commodities.id AS commodity_id,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          cultivars.description AS cultivar_description,
          farm_groups.farm_group_code,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          rmt_classes.rmt_class_code,
          rmt_container_material_types.container_material_type_code,
          rmt_container_types.container_type_code,
          rmt_deliveries.truck_registration_number AS rmt_delivery_truck_registration_number,
          seasons.season_code,
          rmt_bins.location_id,
              CASE
                  WHEN rmt_bins.bin_tipped THEN 'gray'::text
                  ELSE NULL::text
              END AS colour_rule,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status

         FROM rmt_bins
         LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
         LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
         LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id 
         LEFT JOIN farms ON farms.id = rmt_bins.farm_id
         LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
         LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
         LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
         LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
         LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
         LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
         LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
         LEFT JOIN rmt_delivery_destinations ON rmt_delivery_destinations.id = rmt_deliveries.rmt_delivery_destination_id
         LEFT JOIN locations ON locations.id = rmt_bins.location_id
         LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_tipped_id
         LEFT JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
         LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
         LEFT JOIN rmt_sizes ON rmt_sizes.id=rmt_bins.rmt_size_id;

      
      ALTER TABLE public.vw_bins
          OWNER TO postgres;

    SQL

    # Carton Label label
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_carton_label_lbl;

      CREATE OR REPLACE VIEW public.vw_carton_label_lbl
      AS SELECT carton_labels.id AS carton_label_id,
          carton_labels.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          carton_labels.label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          pucs.gap_code,
          orchards.orchard_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cvv.marketing_variety_code AS customer_variety_code,
          cvv.description AS customer_variety_description,
          std_fruit_size_counts.size_count_value,
          std_fruit_size_counts.size_count_interval_group,
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
          fn_party_role_delivery_address(carton_labels.marketing_org_party_role_id) AS marketer_address,
          marks.mark_code,
          inventory_codes.inventory_code,
          product_setup_templates.template_name,
          pm_boms.bom_code,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN carton_labels cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = carton_labels.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          carton_labels.client_size_reference,
          carton_labels.client_product_code,
          carton_labels.marketing_order_number,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
              END AS inspection_tm,
          fn_party_role_name(product_resource_allocations.target_customer_party_role_id) AS target_customer,
          seasons.season_code,
          pm_subtypes.subtype_code,
          pm_types.pm_type_code,
          cartons_per_pallet.cartons_per_pallet,
          pm_products.product_code,
          carton_labels.pallet_number,
          carton_labels.sell_by_code,
          grades.grade_code,
          carton_labels.product_chars,
          carton_labels.pick_ref,
          carton_labels.phc,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          contract_workers.personnel_number,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          carton_labels.gtin_code,
          pallet_formats.description AS pallet_format_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number
         FROM carton_labels
           LEFT JOIN production_runs ON production_runs.id = carton_labels.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = carton_labels.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
           JOIN farms ON farms.id = carton_labels.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = carton_labels.puc_id
           JOIN orchards ON orchards.id = carton_labels.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
           LEFT JOIN grades ON grades.id = carton_labels.grade_id
           LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = carton_labels.std_fruit_size_count_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = carton_labels.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = carton_labels.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = carton_labels.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
           JOIN marks ON marks.id = carton_labels.mark_id
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
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = carton_labels.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id
           LEFT JOIN party_roles mkt_pr ON mkt_pr.id = carton_labels.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = mkt_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = carton_labels.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = carton_labels.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = carton_labels.marketing_orchard_id
           LEFT JOIN rmt_codes ON rmt_codes.id = production_runs.rmt_code_id
           LEFT JOIN rmt_classes ON rmt_classes.id = carton_labels.rmt_class_id;
    SQL

    # Carton Label pallet seq
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_carton_label_pseq;

      CREATE OR REPLACE VIEW public.vw_carton_label_pseq
      AS SELECT pallet_sequences.id,
          cartons.carton_label_id,
          pallet_sequences.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          carton_labels.label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          pucs.gap_code,
          orchards.orchard_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cvv.marketing_variety_code AS customer_variety_code,
          cvv.description AS customer_variety_description,
          std_fruit_size_counts.size_count_value,
          std_fruit_size_counts.size_count_interval_group,
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(pallet_sequences.marketing_org_party_role_id) AS marketer,
          fn_party_role_delivery_address(pallet_sequences.marketing_org_party_role_id) AS marketer_address,
          marks.mark_code,
          inventory_codes.inventory_code,
          product_setup_templates.template_name,
          pm_boms.bom_code,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = pallet_sequences.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          pallet_sequences.client_size_reference,
          pallet_sequences.client_product_code,
          pallet_sequences.marketing_order_number,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
              END AS inspection_tm,
          fn_party_role_name(product_resource_allocations.target_customer_party_role_id) AS target_customer,
          seasons.season_code,
          pm_subtypes.subtype_code,
          pm_types.pm_type_code,
          cartons_per_pallet.cartons_per_pallet,
          pm_products.product_code,
          pallet_sequences.pallet_number,
          pallet_sequences.sell_by_code,
          grades.grade_code,
          pallet_sequences.product_chars,
          pallet_sequences.pick_ref,
          carton_labels.phc,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          contract_workers.personnel_number,
          carton_labels.created_at::date AS packed_date,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          pallet_sequences.gtin_code,
          pallet_formats.description AS pallet_format_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN cartons ON
              CASE
                  WHEN pallet_sequences.scanned_from_carton_id IS NULL THEN cartons.pallet_sequence_id = pallet_sequences.id
                  ELSE cartons.id = pallet_sequences.scanned_from_carton_id
              END
           JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
           LEFT JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = pallet_sequences.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = pallet_sequences.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           LEFT JOIN pm_boms ON pm_boms.id = pallet_sequences.pm_bom_id
           LEFT JOIN pm_subtypes ON pm_subtypes.id = pallet_sequences.pm_subtype_id
           LEFT JOIN pm_types ON pm_types.id = pallet_sequences.pm_type_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT JOIN target_markets ON target_markets.id = pallet_sequences.target_market_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = pallet_sequences.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = pallet_sequences.contract_worker_id
           LEFT JOIN party_roles mkt_pr ON mkt_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = mkt_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = pallet_sequences.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = pallet_sequences.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = pallet_sequences.marketing_orchard_id
           LEFT JOIN rmt_codes ON rmt_codes.id = production_runs.rmt_code_id
           LEFT JOIN rmt_classes ON rmt_classes.id = pallet_sequences.rmt_class_id;
    SQL

    # Carton Label product setup
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_carton_label_pset;

      CREATE OR REPLACE VIEW public.vw_carton_label_pset
      AS SELECT product_setups.id AS carton_label_id,
          product_resource_allocations.id AS product_resource_allocation_id,
          product_resource_allocations.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          label_templates.label_template_name AS label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          COALESCE(mkt_org_pucs.puc_code, pucs.puc_code) AS puc_code,
          pucs.gap_code,
          orchards.orchard_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          marketing_varieties.marketing_variety_code,
          marketing_varieties.description AS marketing_variety_description,
          COALESCE(cvv.marketing_variety_code, marketing_varieties.marketing_variety_code) AS customer_or_marketing_variety,
          COALESCE(cvv.description, marketing_varieties.description) AS customer_or_marketing_variety_desc,
          cvv.marketing_variety_code AS customer_variety_code,
          cvv.description AS customer_variety_description,
          std_fruit_size_counts.size_count_value,
          std_fruit_size_counts.size_count_interval_group,
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(product_setups.marketing_org_party_role_id) AS marketer,
          fn_party_role_delivery_address(product_setups.marketing_org_party_role_id) AS marketer_address,
          marks.mark_code,
          inventory_codes.inventory_code,
          product_setup_templates.template_name,
          pm_boms.bom_code,
          ( SELECT array_agg(clt.treatment_code) AS array_agg
                 FROM ( SELECT t.treatment_code
                         FROM treatments t
                           JOIN product_setups cl ON t.id = ANY (cl.treatment_ids)
                        WHERE cl.id = product_setups.id
                        ORDER BY t.treatment_code DESC) clt) AS treatments,
          product_setups.client_size_reference,
          product_setups.client_product_code,
          product_setups.marketing_order_number,
          target_market_groups.target_market_group_name AS packed_tm_group,
          target_markets.target_market_name,
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
              END AS inspection_tm,
          fn_party_role_name(product_resource_allocations.target_customer_party_role_id) AS target_customer,
          seasons.season_code,
          'UNK'::text AS subtype_code,
          'UNK'::text AS pm_type_code,
          cartons_per_pallet.cartons_per_pallet,
          'UNKNOWN'::text AS product_code,
          'UNKNOWN'::text AS pallet_number,
          product_setups.sell_by_code,
          grades.grade_code,
          product_setups.product_chars,
          (("substring"(to_char('now'::text::date::timestamp with time zone, 'IW'::text), '.$'::text) || date_part('dow'::text, 'now'::text::date)::text) || (packhouses.resource_properties ->> 'packhouse_no'::text)) || "substring"(to_char('now'::text::date::timestamp with time zone, 'IW'::text), '.'::text) AS pick_ref,
          COALESCE(lines.resource_properties ->> 'phc'::text, packhouses.resource_properties ->> 'phc'::text) AS phc,
          lines.resource_properties ->> 'gln'::text AS gln_code,
              CASE
                  WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                  ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END AS count_swap_rule,
          'UNK'::text AS personnel_number,
          mkt_org_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          product_setups.gtin_code,
          pallet_formats.description AS pallet_format_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number
         FROM product_resource_allocations
           JOIN production_runs ON production_runs.id = product_resource_allocations.production_run_id
           JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           JOIN plant_resources packhouses ON packhouses.id = production_runs.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = production_runs.production_line_id
           LEFT JOIN label_templates ON label_templates.id = product_resource_allocations.label_template_id
           JOIN farms ON farms.id = production_runs.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = production_runs.puc_id
           LEFT JOIN orchards ON orchards.id = production_runs.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
           LEFT JOIN grades ON grades.id = product_setups.grade_id
           LEFT JOIN cultivars ON cultivars.id = production_runs.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = product_setups.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = product_setups.customer_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = product_setups.std_fruit_size_count_id
           LEFT JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = product_setups.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = product_setups.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = product_setups.basic_pack_code_id
           JOIN standard_pack_codes ON standard_pack_codes.id = product_setups.standard_pack_code_id
           JOIN marks ON marks.id = product_setups.mark_id
           JOIN inventory_codes ON inventory_codes.id = product_setups.inventory_code_id
           LEFT JOIN pm_boms ON pm_boms.id = product_setups.pm_bom_id
           JOIN target_market_groups ON target_market_groups.id = product_setups.packed_tm_group_id
           LEFT JOIN target_markets ON target_markets.id = product_setups.target_market_id
           JOIN seasons ON seasons.id = production_runs.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = product_setups.cartons_per_pallet_id
           JOIN pallet_formats ON pallet_formats.id = product_setups.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = product_setups.standard_pack_code_id
           LEFT JOIN party_roles mkt_pr ON mkt_pr.id = product_setups.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = mkt_pr.organization_id
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = production_runs.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN registered_orchards ON registered_orchards.puc_code::text = mkt_org_pucs.puc_code::text AND registered_orchards.cultivar_code::text = cultivars.cultivar_code AND registered_orchards.marketing_orchard
           LEFT JOIN rmt_codes ON rmt_codes.id = production_runs.rmt_code_id
           LEFT JOIN rmt_classes ON rmt_classes.id = product_setups.rmt_class_id;
    SQL

    # Pallet Label
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_pallet_label;

      CREATE OR REPLACE VIEW public.vw_pallet_label
      AS SELECT pallet_sequences.id,
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
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_reference_or_actual_count,
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
              CASE
                  WHEN target_markets.inspection_tm THEN target_markets.target_market_name
                  ELSE target_market_groups.target_market_group_name
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
          pallet_sequences.product_chars,
          marketing_pucs.puc_code AS marketing_puc,
          registered_orchards.orchard_code AS marketing_orchard,
          COALESCE(target_markets.target_market_name, target_market_groups.target_market_group_name) AS tm_or_packed_tm,
          production_runs.run_batch_number
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           LEFT JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (( SELECT rmt_bins.farm_id
                 FROM rmt_bins
                WHERE rmt_bins.production_run_tipped_id = production_runs.id
               LIMIT 1))
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
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
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id
           LEFT JOIN pucs marketing_pucs ON marketing_pucs.id = pallet_sequences.marketing_puc_id
           LEFT JOIN registered_orchards ON registered_orchards.id = pallet_sequences.marketing_orchard_id;
    SQL

    # Rebin Label
    # -------------------------------------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_rebin_label;

      CREATE OR REPLACE VIEW public.vw_rebin_label
      AS SELECT rmt_bins.id,
          rmt_bins.bin_asset_number,
          rmt_bins.gross_weight,
          rmt_bins.nett_weight,
          rmt_bins.production_run_rebin_id AS production_run_id,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          to_char(timezone('Africa/Johannesburg'::text, rmt_bins.created_at), 'YYYY-mm-dd HH24:MI'::text) AS created_at,
          plant_resources.plant_resource_code AS line,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_container_material_types.container_material_type_code,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          rmt_codes.rmt_code AS rmt_code,
          production_runs.run_batch_number
         FROM rmt_bins
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_sizes ON rmt_sizes.id = rmt_bins.rmt_size_id
           LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_rebin_id
           LEFT JOIN rmt_codes ON rmt_codes.id = production_runs.rmt_code_id
           LEFT JOIN plant_resources ON plant_resources.id = production_runs.production_line_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id;
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
        fn_party_role_name(carton_labels.target_customer_party_role_id) AS target_customer,
        carton_labels.rmt_container_material_owner_id,
        CONCAT(container_material_type_code, ' - ', fn_party_role_name(rmt_material_owner_party_role_id)) AS rmt_container_material_owner
        
       FROM carton_labels
         LEFT JOIN cartons ON carton_labels.id = cartons.carton_label_id
         LEFT JOIN production_runs ON production_runs.id = carton_labels.production_run_id
         LEFT JOIN product_setup_templates ON product_setup_templates.id = production_runs.product_setup_template_id
         LEFT JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
         LEFT JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
         LEFT JOIN plant_resources packpoints ON packpoints.id = carton_labels.resource_id
         LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = cartons.palletizing_bay_resource_id
         LEFT JOIN system_resources ON packpoints.system_resource_id = system_resources.id
         JOIN farms ON farms.id = carton_labels.farm_id
         JOIN pucs ON pucs.id = carton_labels.puc_id
         JOIN orchards ON orchards.id = carton_labels.orchard_id
         JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
         LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
         LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
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
         LEFT JOIN pm_products ru_pm_products ON ru_pm_products.id = carton_labels.ru_labour_product_id
         LEFT JOIN rmt_container_material_owners ON rmt_container_material_owners.id = carton_labels.rmt_container_material_owner_id
         LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id;

       ALTER TABLE public.vw_cartons
        OWNER TO postgres;
    SQL

    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW vw_pallet_sequence_flat;
      DROP VIEW vw_pallet_sequences_aggregated;
      DROP VIEW vw_pallet_sequences;

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
        CASE
            WHEN pm_boms.nett_weight IS NULL THEN ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton
            ELSE ps.carton_quantity::numeric * (NULLIF(pm_boms.nett_weight, 0::numeric) / standard_product_weights_for_commodity.nett_weight)
        END AS standard_cartons,
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
      LEFT JOIN standard_product_weights standard_product_weights_for_commodity ON standard_product_weights_for_commodity.commodity_id = commodities.id AND standard_product_weights_for_commodity.is_standard_carton       
      LEFT JOIN rmt_classes ON rmt_classes.id = ps.rmt_class_id
      LEFT JOIN colour_percentages ON colour_percentages.id = ps.colour_percentage_id
      WHERE ps.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_pallet_sequences
      OWNER TO postgres;

    SQL

    # vw_pallet_sequence_flat
    # ----------------------------------------------
    run <<~SQL
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
          production_regions.inspection_region AS production_area,
          pucs.puc_code AS puc,
          orchards.orchard_code AS orchard,
          commodities.code AS commodity,
          cultivar_groups.cultivar_group_code AS cultivar_group,
          cultivars.cultivar_name AS cultivar,
          marketing_varieties.marketing_variety_code AS marketing_variety,
          marketing_varieties.inspection_variety,
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
          std_fruit_size_counts.marketing_size_range_mm AS diameter_range,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          pm_boms.nett_weight AS pm_bom_nett_weight, 
          standard_product_weights.ratio_to_standard_carton, 
          standard_product_weights_for_commodity.nett_weight AS standard_product_weights_for_commodity_nett_weight,
          CASE
              WHEN pm_boms.nett_weight IS NULL THEN ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton
              ELSE ps.carton_quantity::numeric * (NULLIF(pm_boms.nett_weight, 0::numeric) / standard_product_weights_for_commodity.nett_weight)
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
          COALESCE(p.gross_weight, load_containers.actual_payload / (( SELECT count(*) AS count
                 FROM pallets
                WHERE pallets.load_id = loads.id))::numeric) AS gross_weight,
          p.gross_weight_measured_at,
          p.nett_weight,
          ps.nett_weight AS sequence_nett_weight,
          COALESCE(p.gross_weight / p.carton_quantity::numeric, load_containers.actual_payload / (( SELECT sum(pallets.carton_quantity) AS sum
                 FROM pallets
                WHERE pallets.load_id = loads.id))::numeric) AS carton_gross_weight,
          ps.nett_weight / ps.carton_quantity::numeric AS carton_nett_weight,
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
          load_containers.container_seal_code,
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
          concat(rmt_container_material_types.container_material_type_code, ' - ', fn_party_role_name(rmt_container_material_owners.rmt_material_owner_party_role_id)) AS rmt_container_material_owner,
          ps.colour_percentage_id,
          colour_percentages.colour_percentage,
          colour_percentages.description AS colour_description,
          ps.work_order_item_id,
          fn_work_order_item_code(ps.work_order_item_id) AS work_order_item_code,
              CASE
                  WHEN p.gross_weight IS NULL THEN ps.nett_weight / (( SELECT sum(pallet_sequences.nett_weight) AS sum
                     FROM pallet_sequences
                    WHERE (pallet_sequences.pallet_id IN ( SELECT pallets.id
                             FROM pallets
                            WHERE pallets.load_id = loads.id)))) * load_containers.actual_payload
                  ELSE ps.carton_quantity::numeric / p.carton_quantity::numeric * p.gross_weight
              END AS sequence_gross_weight,
          p.edi_in_load_number

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
           LEFT JOIN standard_product_weights standard_product_weights_for_commodity ON standard_product_weights_for_commodity.commodity_id = commodities.id AND standard_product_weights_for_commodity.is_standard_carton       
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

    # vw_pallet_sequences_aggregated
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences_aggregated
       AS
      SELECT
          vw_pallet_sequences.pallet_id,
          vw_pallet_sequences.pallet_number,
          array_agg(DISTINCT vw_pallet_sequences.pallet_sequence_id::text) AS pallet_sequence_ids,
          count(vw_pallet_sequences.pallet_sequence_id) AS count,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.status::text),NULL) AS statuses,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_sequence_number::text),NULL) AS pallet_sequence_numbers,
          array_agg(vw_pallet_sequences.nett_weight::text) AS nett_weights,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_at::text),NULL) AS packed_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_date::text),NULL) AS packed_dates,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_week::text),NULL) AS packed_weeks,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.production_run::text),NULL) AS production_runs,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.season_id::text),NULL) AS season_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.season::text),NULL) AS seasons,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.farm_id::text),NULL) AS farm_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.farm::text),NULL) AS farms,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.farm_group::text),NULL) AS farm_groups,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.production_region::text),NULL) AS production_regions,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.puc_id::text),NULL) AS puc_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.puc::text),NULL) AS pucs,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.orchard_id::text),NULL) AS orchard_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.orchard::text),NULL) AS orchards,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_id::text),NULL) AS cultivar_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.commodity::text),NULL) AS commodities,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_group_id::text),NULL) AS cultivar_group_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_group::text),NULL) AS cultivar_groups,
          -- array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_id::text),NULL) AS cultivar_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar_name::text),NULL) AS cultivar_names,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cultivar::text),NULL) AS cultivars,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.resource_allocation_id::text),NULL) AS resource_allocation_ids,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.packhouse_resource_id::text),NULL) AS packhouse_resource_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packhouse::text),NULL) AS packhouses,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.production_line_id::text),NULL) AS production_line_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.line::text),NULL) AS lines,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_variety_id::text),NULL) AS marketing_variety_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_variety::text),NULL) AS marketing_varieties,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.customer_variety_id::text),NULL) AS customer_variety_ids,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.variety_as_customer_variety_id::text),NULL) AS variety_as_customer_variety_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.customer_marketing_variety::text),NULL) AS customer_marketing_varieties,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_orchard_id::text),NULL) AS marketing_orchard_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_orchard::text),NULL) AS marketing_orchards,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_puc_id::text),NULL) AS marketing_puc_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_puc::text),NULL) AS marketing_pucs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.std_fruit_size_count_id::text),NULL) AS std_fruit_size_count_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_size::text),NULL) AS standard_sizes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.count_group::text),NULL) AS count_groups,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_count::text),NULL) AS standard_counts,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.basic_pack_id::text),NULL) AS basic_pack_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.basic_pack::text),NULL) AS basic_packs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_pack_id::text),NULL) AS standard_pack_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_pack::text),NULL) AS standard_packs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.fruit_actual_counts_for_pack_id::text),NULL) AS fruit_actual_counts_for_pack_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.actual_count::text),NULL) AS actual_counts,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.edi_size_count::text),NULL) AS edi_size_counts,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.fruit_size_reference_id::text),NULL) AS fruit_size_reference_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.size_reference::text),NULL) AS size_references,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_org_party_role_id::text),NULL) AS marketing_org_party_role_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_org::text),NULL) AS marketing_orgs,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_tm_group_id::text),NULL) AS packed_tm_group_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packed_tm_group::text),NULL) AS packed_tm_groups,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.mark_id::text),NULL) AS mark_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.mark::text),NULL) AS marks,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_mark_id::text),NULL) AS pm_mark_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.packaging_marks::text),NULL) AS packaging_marks,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.inventory_code_id::text),NULL) AS inventory_code_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.inventory_code::text),NULL) AS inventory_codes,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_format_id::text),NULL) AS pallet_format_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_format::text),NULL) AS pallet_formats,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet_id::text),NULL) AS cartons_per_pallet_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.cartons_per_pallet::text),NULL) AS cartons_per_pallets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_bom_id::text),NULL) AS pm_bom_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.bom_code::text),NULL) AS bom_codes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.system_code::text),NULL) AS system_codes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.extended_columns::text),NULL) AS extended_columns,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.client_size_reference::text),NULL) AS client_size_references,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.client_product::text),NULL) AS client_products,
          --array_merge_agg(DISTINCT vw_pallet_sequences.treatment_ids) AS treatment_ids,
          array_merge_agg(DISTINCT vw_pallet_sequences.treatments) AS treatments,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.marketing_order_number::text),NULL) AS marketing_order_numbers,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_type_id::text),NULL) AS pm_type_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_type::text),NULL) AS pm_types,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_subtype_id::text),NULL) AS pm_subtype_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pm_subtype::text),NULL) AS pm_subtypes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.carton_quantity::text),NULL) AS carton_quantities,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.scanned_carton::text),NULL) AS scanned_cartons,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.scrapped_at::text),NULL) AS scrapped_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.exit_reference::text),NULL) AS exit_references,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verification_result::text),NULL) AS verification_results,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.pallet_verification_failure_reason_id::text),NULL) AS pallet_verification_failure_reason_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verification_failure_reason::text),NULL) AS verification_failure_reasons,
          bool_and(vw_pallet_sequences.verified) AS verified,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verified_by::text),NULL) AS verified_by,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.verified_at::text),NULL) AS verified_at,
          bool_and(vw_pallet_sequences.verification_passed) AS verifications_passed,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.pick_reference::text),NULL) AS pick_references,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.grade_id::text),NULL) AS grade_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.grade::text),NULL) AS grades,
          bool_and(vw_pallet_sequences.rmt_grade) AS rmt_grades,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.scrapped_from_pallet_id::text),NULL) AS scrapped_from_pallet_ids,
          bool_and(vw_pallet_sequences.removed_from_pallet) AS removed_from_pallets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_id::text),NULL) AS removed_from_pallet_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.removed_from_pallet_at::text),NULL) AS removed_from_pallet_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.sell_by_code::text),NULL) AS sell_by_codes,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.product_chars::text),NULL) AS product_chars,
          bool_and(vw_pallet_sequences.depot_pallet) AS depot_pallets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.personnel_identifier_id::text),NULL) AS personnel_identifier_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.hardware_type::text),NULL) AS hardware_types,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.identifier::text),NULL) AS identifiers,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.contract_worker_id::text),NULL) AS contract_worker_ids,
          bool_and(vw_pallet_sequences.repacked) AS repacked,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.repacked_at::text),NULL) AS repacked_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.repacked_from_pallet_id::text),NULL) AS repacked_from_pallet_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.repacked_from_pallet_number::text),NULL) AS repacked_from_pallet_numbers,
          bool_and(vw_pallet_sequences.failed_otmc) AS failed_otmc,
          --array_merge_agg(DISTINCT vw_pallet_sequences.failed_otmc_result_ids) AS failed_otmc_result_ids,
          array_merge_agg(DISTINCT vw_pallet_sequences.failed_otmc_results) AS failed_otmc_results,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.phyto_data::text),NULL) AS phyto_data,
          bool_and(vw_pallet_sequences.active) AS active,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.created_by::text),NULL) AS created_by,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.created_at::text),NULL) AS created_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.updated_at::text),NULL) AS updated_at,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.target_market::text),NULL) AS target_markets,
          --array_remove(array_agg(DISTINCT vw_pallet_sequences.target_customer_party_role_id),NULL) AS target_customer_party_role_ids,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.target_customer::text),NULL) AS target_customers,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_cartons::text),NULL) AS standard_cartons,
          array_remove(array_agg(DISTINCT vw_pallet_sequences.rmt_class::text),NULL) AS rmt_classes
      FROM vw_pallet_sequences
      GROUP BY vw_pallet_sequences.pallet_id, vw_pallet_sequences.pallet_number;

      ALTER TABLE public.vw_pallet_sequences_aggregated
          OWNER TO postgres;
    SQL

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

    # vw_rmt_bins_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_rmt_bins_flat;

      CREATE VIEW public.vw_rmt_bins_flat AS
       SELECT rmt_bins.id,
          COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number) AS asset_number,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status,
          rmt_bins.presort_staging_run_child_id,
          rmt_bins.tipped_in_presort_at,
          rmt_bins.staged_for_presorting_at,
          rmt_bins.presort_tip_lot_number,
          rmt_bins.mixed,
          rmt_bins.sample_bin,
          rmt_bins.presorted,
          rmt_bins.main_presort_run_lot_number,
          rmt_bins.staged_for_presorting,
          rmt_bins.qty_bins,
          rmt_bins.legacy_data,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_bins.qty_bins = 1 AS discrete_bin,
          rmt_bins.qty_inner_bins,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.weighed_manually,
          rmt_bins.active,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_bins.location_id,
          locations.location_long_code,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          plant_resources.plant_resource_code AS packhouse,
          rmt_bins.season_id,
          seasons.season_code,
          rmt_bins.farm_id,
          farm_groups.farm_group_code,
          farms.farm_code,
          rmt_bins.puc_id,
          pucs.puc_code,
          rmt_bins.orchard_id,
          orchards.orchard_code,
          rmt_bins.cultivar_group_id,
          cultivar_groups.cultivar_group_code,
          rmt_bins.cultivar_id,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          cultivars.description AS cultivar_description,
          commodities.code AS commodity_code,
          rmt_bins.rmt_class_id,
          rmt_classes.rmt_class_code,
          rmt_bins.rmt_material_owner_party_role_id,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          rmt_bins.rmt_container_type_id,
          rmt_container_types.container_type_code,
          rmt_bins.rmt_container_material_type_id,
          rmt_container_material_types.container_material_type_code,
          rmt_bins.rmt_inner_container_type_id,
          rmt_inner_container_types.container_type_code AS inner_container_type_code,
          rmt_bins.rmt_inner_container_material_id,
          rmt_inner_container_material_types.container_material_type_code AS inner_container_material_type_code,
          rmt_bins.scrapped_rmt_delivery_id,
          rmt_bins.rmt_delivery_id,
          rmt_delivery_destinations.delivery_destination_code,
          rmt_deliveries.date_picked AS picked_at,
          rmt_deliveries.truck_registration_number AS delivery_truck_registration_number,
          rmt_bins.exit_ref,
          rmt_bins.exit_ref IS NULL AS null_exit_ref,
          rmt_bins.exit_ref_date_time AS exit_ref_at,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.bin_asset_number,
          rmt_bins.bin_received_date_time AS bin_received_at,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.tipped_asset_number,
          rmt_bins.bin_tipped,
          rmt_bins.tipped_manually,
          rmt_bins.bin_tipped_date_time AS bin_tipped_at,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          date_part('week'::text, rmt_bins.bin_tipped_date_time) AS bin_tipped_week,
          rmt_bins.shipped_asset_number,
          bin_loads.shipped IS TRUE AS shipped,
          bin_loads.shipped_at,
          bin_load_products.bin_load_id,
          rmt_bins.bin_load_product_id,
          rmt_bins.scrapped_bin_asset_number,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          rmt_bins.scrap_remarks,
          rmt_bins.unscrapped_at,
          rmt_bins.production_run_rebin_id,
          rmt_bins.rebin_created_at,
          rmt_bins.avg_gross_weight,
          farm_sections.farm_section_name,
          fn_party_role_name(farm_sections.farm_manager_party_role_id) AS farm_manager,
          floor(ABS(date_part('epoch', COALESCE(rmt_bins.bin_received_date_time::timestamp, rmt_bins.created_at::timestamp) - COALESCE(rmt_bins.exit_ref_date_time::timestamp, current_timestamp)) / 86400)) AS age,
          lines.plant_resource_code AS tip_line,
          rmt_bins.coldroom_events,
          concat_ws(' ',
                    location_coldroom_events.event_name,
                    to_char (location_coldroom_events.created_at, 'YYYY-MM-DD HH24:MI:SS'),
                    cold_loc.location_long_code) AS last_coldroom_event,
          rmt_bins.rmt_classifications,
          ( SELECT array_agg(DISTINCT rmt_classifications.rmt_classification) AS array_agg
            FROM rmt_classifications
            WHERE rmt_classifications.id = ANY (rmt_bins.rmt_classifications)
            GROUP BY rmt_bins.id) AS classifications,
          rmt_bins.main_ripeness_treatment_id,
          main_ripeness_treatments.treatment_code AS main_ripeness_treatment,
          rmt_bins.main_cold_treatment_id,
          main_cold_treatments.treatment_code AS main_cold_treatment,
          rmt_bins.rmt_treatments,
          ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
            FROM treatments
            WHERE treatments.id = ANY (rmt_bins.rmt_treatments)
            GROUP BY rmt_bins.id) AS treatments,
          rmt_bins.rmt_code_id,
          rmt_codes.rmt_code,
          rmt_handling_regimes.regime_code,
          ripeness_treatments.treatment_code as actual_ripeness_treatment,
          cold_treatments.treatment_code as actual_cold_treatment

         FROM rmt_bins
           LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN farm_sections ON farm_sections.id = orchards.farm_section_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
           LEFT JOIN rmt_container_material_types rmt_inner_container_material_types ON rmt_inner_container_material_types.id = rmt_bins.rmt_inner_container_material_id
           LEFT JOIN rmt_container_types rmt_inner_container_types ON rmt_inner_container_types.id = rmt_bins.rmt_inner_container_type_id
           LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
           LEFT JOIN rmt_delivery_destinations ON rmt_delivery_destinations.id = rmt_deliveries.rmt_delivery_destination_id
           LEFT JOIN locations ON locations.id = rmt_bins.location_id
           LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_tipped_id
           LEFT JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = production_runs.production_line_id
           LEFT JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
           LEFT JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
           LEFT JOIN rmt_sizes ON rmt_sizes.id=rmt_bins.rmt_size_id
           LEFT JOIN location_coldroom_events ON location_coldroom_events.id = rmt_bins.coldroom_events[array_upper(rmt_bins.coldroom_events, 1)]
           LEFT JOIN locations cold_loc ON cold_loc.id = location_coldroom_events.location_id
           LEFT JOIN treatments main_ripeness_treatments ON main_ripeness_treatments.id = rmt_bins.main_ripeness_treatment_id
           LEFT JOIN treatments main_cold_treatments ON main_cold_treatments.id = rmt_bins.main_cold_treatment_id
           LEFT JOIN rmt_codes ON rmt_codes.id = rmt_bins.rmt_code_id
           LEFT JOIN rmt_handling_regimes ON rmt_handling_regimes.id = rmt_codes.rmt_handling_regime_id
           LEFT JOIN treatments AS cold_treatments ON cold_treatments.id = rmt_bins.actual_cold_treatment_id
           LEFT JOIN treatments AS ripeness_treatments ON ripeness_treatments.id = rmt_bins.actual_ripeness_treatment_id;
      SQL
  end
end
