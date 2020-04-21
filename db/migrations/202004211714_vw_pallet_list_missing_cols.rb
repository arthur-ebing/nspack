Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_pallet_label;

      CREATE OR REPLACE VIEW public.vw_pallet_label AS
       SELECT pallet_sequences.id,
          pallet_sequences.pallet_id,
          pallet_sequences.pallet_sequence_number,
          farms.farm_code,
          orchards.orchard_code,
          to_char(pallet_sequences.verified_at, 'YYYY-mm-dd') AS pack_date,
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
          pucs.puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
          ( SELECT string_agg(clt.treatment_code, ', ') AS str_agg
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
          std_fruit_size_counts.size_count_interval_group
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (SELECT farm_id FROM rmt_bins WHERE production_run_tipped_id = production_runs.id LIMIT 1)
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
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id
                 AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = pallet_sequences.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT OUTER JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT OUTER JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id;

      ALTER TABLE public.vw_pallet_label
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_pallet_label;

      CREATE OR REPLACE VIEW public.vw_pallet_label AS
       SELECT pallet_sequences.id,
          pallet_sequences.pallet_id,
          pallet_sequences.pallet_sequence_number,
          farms.farm_code,
          orchards.orchard_code,
          to_char(pallet_sequences.verified_at, 'YYYY-mm-dd') AS pack_date,
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
          pucs.puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
          ( SELECT string_agg(clt.treatment_code, ', ') AS str_agg
            FROM ( SELECT t.treatment_code
                   FROM treatments t
                   JOIN pallet_sequences cl ON t.id = ANY (cl.treatment_ids)
                  WHERE cl.id = pallet_sequences.id
                  ORDER BY t.treatment_code DESC) clt) AS treatments
         FROM pallet_sequences
           JOIN pallets ON pallets.id = pallet_sequences.pallet_id
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           LEFT JOIN farms ON farms.id = (SELECT farm_id FROM rmt_bins WHERE production_run_tipped_id = production_runs.id LIMIT 1)
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
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id
                 AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN marks ON marks.id = pallet_sequences.mark_id
           JOIN pucs ON pucs.id = pallet_sequences.puc_id
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           LEFT JOIN customer_variety_varieties ON customer_variety_varieties.id = pallet_sequences.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_variety_varieties.marketing_variety_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT OUTER JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT OUTER JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id;

      ALTER TABLE public.vw_pallet_label
        OWNER TO postgres;
    SQL
  end
end
