Sequel.migration do
  up do
    # Carton Label product setup - make orchard optional
    # --------------------------------------------------
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_carton_label_pset
       AS
       SELECT product_setups.id AS carton_label_id,
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
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(product_setups.marketing_org_party_role_id) AS marketer,
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
          CASE WHEN target_markets.inspection_tm THEN
            target_markets.target_market_name
          ELSE
            target_market_groups.target_market_group_name
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
          'UNK'::text AS personnel_number
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
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
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
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = production_runs.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_carton_label_pset
       AS
       SELECT product_setups.id AS carton_label_id,
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
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(product_setups.marketing_org_party_role_id) AS marketer,
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
          CASE WHEN target_markets.inspection_tm THEN
            target_markets.target_market_name
          ELSE
            target_market_groups.target_market_group_name
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
          'UNK'::text AS personnel_number
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
           JOIN orchards ON orchards.id = production_runs.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
           LEFT JOIN grades ON grades.id = product_setups.grade_id
           LEFT JOIN cultivars ON cultivars.id = production_runs.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
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
           LEFT JOIN farm_puc_orgs ON farm_puc_orgs.farm_id = production_runs.farm_id AND farm_puc_orgs.organization_id = mkt_pr.organization_id
           LEFT JOIN pucs mkt_org_pucs ON mkt_org_pucs.id = farm_puc_orgs.puc_id;
    SQL
  end
end
