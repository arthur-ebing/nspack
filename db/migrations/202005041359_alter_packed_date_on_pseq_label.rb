Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_carton_label_pseq;
      CREATE OR REPLACE VIEW public.vw_carton_label_pseq AS
       SELECT pallet_sequences.id,
          cartons.carton_label_id,
          pallet_sequences.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          carton_labels.label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          pucs.puc_code,
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
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(pallet_sequences.marketing_org_party_role_id) AS marketer,
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
          carton_labels.created_at::date AS packed_date
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN cartons ON cartons.id = pallet_sequences.scanned_from_carton_id
           JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = pallet_sequences.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = pallet_sequences.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = pallet_sequences.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
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
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = pallet_sequences.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = pallet_sequences.contract_worker_id;
      
      ALTER TABLE public.vw_carton_label_pseq
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_carton_label_pseq;
      CREATE OR REPLACE VIEW public.vw_carton_label_pseq AS
       SELECT pallet_sequences.id,
          cartons.carton_label_id,
          pallet_sequences.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          carton_labels.label_name,
          farms.farm_code,
          farm_groups.farm_group_code,
          pucs.puc_code,
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
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(pallet_sequences.marketing_org_party_role_id) AS marketer,
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
          pallet_sequences.created_at::date AS packed_date
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN cartons ON cartons.id = pallet_sequences.scanned_from_carton_id
           JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = pallet_sequences.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = pallet_sequences.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN orchards ON orchards.id = pallet_sequences.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = pallet_sequences.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
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
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = pallet_sequences.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = pallet_sequences.contract_worker_id;
      
      ALTER TABLE public.vw_carton_label_pseq
          OWNER TO postgres;
    SQL
  end
end
