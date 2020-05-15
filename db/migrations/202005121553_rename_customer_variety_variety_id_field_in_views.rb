Sequel.migration do
  up do
    alter_table(:product_setups) do
      add_foreign_key [:customer_variety_id], :customer_varieties, name: :product_setups_customer_variety_id_fkey
    end

    alter_table(:carton_labels) do
      add_foreign_key [:customer_variety_id], :customer_varieties, name: :carton_labels_customer_variety_id_fkey
    end

    alter_table(:cartons) do
      add_foreign_key [:customer_variety_id], :customer_varieties, name: :cartons_customer_variety_id_fkey
    end

    alter_table(:pallet_sequences) do
      add_foreign_key [:customer_variety_id], :customer_varieties, name: :pallet_sequences_customer_variety_id_fkey
    end
    run <<~SQL
      DROP VIEW public.vw_carton_label_lbl;
      DROP VIEW public.vw_carton_label_pseq;
      DROP VIEW public.vw_carton_label_pset;
      DROP VIEW public.vw_pallet_label;
      DROP VIEW public.vw_pallet_sequence_flat;
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;
      DROP VIEW public.vw_repacked_pallet_sequence_flat;

      -- 1. vw_carton_label_lbl
      CREATE OR REPLACE VIEW public.vw_carton_label_lbl AS
       SELECT carton_labels.id AS carton_label_id,
          carton_labels.production_run_id,
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
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
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
          contract_workers.personnel_number
         FROM carton_labels
           JOIN production_runs ON production_runs.id = carton_labels.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = carton_labels.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
           JOIN farms ON farms.id = carton_labels.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = carton_labels.puc_id
           JOIN orchards ON orchards.id = carton_labels.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
           LEFT JOIN grades ON grades.id = carton_labels.grade_id
           LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
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
           JOIN seasons ON seasons.id = carton_labels.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = carton_labels.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = carton_labels.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = carton_labels.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = carton_labels.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id;

      ALTER TABLE public.vw_carton_label_lbl
          OWNER TO postgres;

      -- 2. vw_carton_label_pseq
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
          std_fruit_size_counts.marketing_size_range_mm,
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
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = pallet_sequences.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = pallet_sequences.contract_worker_id;

      ALTER TABLE public.vw_carton_label_pseq
          OWNER TO postgres;

      -- 3. vw_carton_label_pset
      CREATE OR REPLACE VIEW public.vw_carton_label_pset AS
       SELECT product_setups.id AS carton_label_id,
          product_resource_allocations.id AS product_resource_allocation_id,
          product_resource_allocations.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          label_templates.label_template_name AS label_name,
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
           JOIN seasons ON seasons.id = production_runs.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = product_setups.cartons_per_pallet_id
           JOIN pallet_formats ON pallet_formats.id = product_setups.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = product_setups.standard_pack_code_id;

      ALTER TABLE public.vw_carton_label_pset
          OWNER TO postgres;

      -- 4. vw_pallet_label
      CREATE OR REPLACE VIEW public.vw_pallet_label AS
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
          pucs.puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
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
          std_fruit_size_counts.size_count_interval_group
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
           LEFT JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id;

      ALTER TABLE public.vw_pallet_label
          OWNER TO postgres;

      -- 5. vw_pallet_sequence_flat
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
          p.internal_inspection_passed,
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
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          (ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5) AS std_ctns,
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
          COALESCE(pod_voyage_ports.atd, pod_voyage_ports.etd) AS departure_date,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.fruit_sticker_pm_product_id,
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
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
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          ps.phyto_data,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          p.target_customer_party_role_id,
          fn_party_role_name(p.target_customer_party_role_id) AS target_customer,
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
           LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
           LEFT JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
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
           LEFT JOIN ( SELECT sq.id,
                  COALESCE(btrim(array_agg(orchard_test_types.test_type_code)::text), ''::text) <> ''::text AS failed_otmc,
                  array_agg(orchard_test_types.test_type_code) AS failed_otmc_results
                 FROM pallet_sequences sq
                   JOIN orchard_test_types ON orchard_test_types.id = ANY (sq.failed_otmc_results)
                GROUP BY sq.id) otmc ON otmc.id = ps.id
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;

      ALTER TABLE public.vw_pallet_sequence_flat
          OWNER TO postgres;

      -- 6. vw_scrapped_pallet_sequence_flat
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
          scrap_reasons.scrap_reason,
          reworks_runs.remarks AS scrapped_remarks,
          reworks_runs."user" AS scrapped_by
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
        ORDER BY p.pallet_number, ps.pallet_sequence_number;

      ALTER TABLE public.vw_scrapped_pallet_sequence_flat
          OWNER TO postgres;

      -- 7. vw_repacked_pallet_sequence_flat
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
    alter_table(:product_setups) do
      drop_constraint :product_setups_customer_variety_id_fkey
    end

    alter_table(:carton_labels) do
      drop_constraint :carton_labels_customer_variety_id_fkey
    end

    alter_table(:cartons) do
      drop_constraint :cartons_customer_variety_id_fkey
    end

    alter_table(:pallet_sequences) do
      drop_constraint :pallet_sequences_customer_variety_id_fkey
    end

    run <<~SQL
      DROP VIEW public.vw_carton_label_lbl;
      DROP VIEW public.vw_carton_label_pseq;
      DROP VIEW public.vw_carton_label_pset;
      DROP VIEW public.vw_pallet_label;
      DROP VIEW public.vw_pallet_sequence_flat;
      DROP VIEW public.vw_scrapped_pallet_sequence_flat;
      DROP VIEW public.vw_repacked_pallet_sequence_flat;
      
      -- 1. vw_carton_label_lbl
      CREATE OR REPLACE VIEW public.vw_carton_label_lbl AS
       SELECT carton_labels.id AS carton_label_id,
          carton_labels.production_run_id,
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
          std_fruit_size_counts.marketing_size_range_mm,
          uoms.uom_code AS size_count_uom,
          fruit_size_references.size_reference,
          fruit_actual_counts_for_packs.actual_count_for_pack,
          basic_pack_codes.basic_pack_code,
          standard_pack_codes.standard_pack_code,
          standard_pack_codes.std_pack_label_code,
          standard_product_weights.nett_weight AS pack_nett_weight,
          fn_party_role_name(carton_labels.marketing_org_party_role_id) AS marketer,
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
          contract_workers.personnel_number
         FROM carton_labels
           JOIN production_runs ON production_runs.id = carton_labels.production_run_id
           LEFT JOIN product_resource_allocations ON product_resource_allocations.id = carton_labels.product_resource_allocation_id
           LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
           LEFT JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = carton_labels.production_line_id
           JOIN farms ON farms.id = carton_labels.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           JOIN pucs ON pucs.id = carton_labels.puc_id
           JOIN orchards ON orchards.id = carton_labels.orchard_id
           JOIN cultivar_groups ON cultivar_groups.id = carton_labels.cultivar_group_id
           LEFT JOIN grades ON grades.id = carton_labels.grade_id
           LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           JOIN marketing_varieties ON marketing_varieties.id = carton_labels.marketing_variety_id
           LEFT JOIN customer_varieties ON customer_varieties.id = carton_labels.customer_variety_variety_id
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
           JOIN seasons ON seasons.id = carton_labels.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = carton_labels.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = carton_labels.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = carton_labels.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = carton_labels.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id;
      
      ALTER TABLE public.vw_carton_label_lbl
          OWNER TO postgres;

      -- 2. vw_carton_label_pseq      
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
          std_fruit_size_counts.marketing_size_range_mm,
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
           LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_variety_id
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
           JOIN seasons ON seasons.id = pallet_sequences.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
           LEFT JOIN pm_products ON pm_products.id = pallets.fruit_sticker_pm_product_id
           JOIN pallet_formats ON pallet_formats.id = pallet_sequences.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
           LEFT JOIN contract_workers ON contract_workers.id = pallet_sequences.contract_worker_id;
      
      ALTER TABLE public.vw_carton_label_pseq
          OWNER TO postgres;

      -- 3. vw_carton_label_pset      
      CREATE OR REPLACE VIEW public.vw_carton_label_pset AS
       SELECT product_setups.id AS carton_label_id,
          product_resource_allocations.id AS product_resource_allocation_id,
          product_resource_allocations.production_run_id,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          label_templates.label_template_name AS label_name,
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
           LEFT JOIN customer_varieties ON customer_varieties.id = product_setups.customer_variety_variety_id
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
           JOIN seasons ON seasons.id = production_runs.season_id
           JOIN cartons_per_pallet ON cartons_per_pallet.id = product_setups.cartons_per_pallet_id
           JOIN pallet_formats ON pallet_formats.id = product_setups.pallet_format_id
           LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id AND standard_product_weights.standard_pack_id = product_setups.standard_pack_code_id;
      
      ALTER TABLE public.vw_carton_label_pset
          OWNER TO postgres;

      -- 4. vw_pallet_label
      CREATE OR REPLACE VIEW public.vw_pallet_label AS
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
          pucs.puc_code,
          seasons.season_code,
          pallet_sequences.marketing_order_number,
          standard_product_weights.nett_weight AS pack_nett_weight,
          uoms.uom_code AS size_count_uom,
          cvv.marketing_variety_code AS customer_variety_code,
          marketing_org.short_description AS marketing_org_short,
          marketing_org.medium_description AS marketing_org_medium,
          target_market_groups.target_market_group_name AS packed_tm_group,
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
          std_fruit_size_counts.size_count_interval_group
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
           LEFT JOIN customer_varieties ON customer_varieties.id = pallet_sequences.customer_variety_variety_id
           LEFT JOIN marketing_varieties cvv ON cvv.id = customer_varieties.variety_as_customer_variety_id
           JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
           LEFT JOIN party_roles org_pr ON org_pr.id = pallet_sequences.marketing_org_party_role_id
           LEFT JOIN organizations marketing_org ON marketing_org.id = org_pr.organization_id;
      
      ALTER TABLE public.vw_pallet_label
          OWNER TO postgres;

      -- 5. vw_pallet_sequence_flat
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
          p.internal_inspection_passed,
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
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          cvv.marketing_variety_code AS customer_variety,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          std_fruit_size_counts.size_count_interval_group AS count_group,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          basic_pack_codes.basic_pack_code AS basic_pack,
          standard_pack_codes.standard_pack_code AS std_pack,
          (ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9,5) AS std_ctns,
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
          COALESCE(pod_voyage_ports.atd, pod_voyage_ports.etd) AS departure_date,
          COALESCE(p.load_id, 0) AS zero_load_id,
          p.fruit_sticker_pm_product_id,
          p.fruit_sticker_pm_product_2_id,
          ps.pallet_verification_failure_reason_id,
          grades.grade_code AS grade,
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
          otmc.failed_otmc_results,
          otmc.failed_otmc,
          ps.phyto_data,
          ps.created_by,
          ps.verified_by,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          p.target_customer_party_role_id,
          fn_party_role_name(p.target_customer_party_role_id) AS target_customer,
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
           LEFT JOIN plant_resources plt_packhouses ON plt_packhouses.id = p.plt_packhouse_resource_id
           LEFT JOIN plant_resources plt_lines ON plt_lines.id = p.plt_line_resource_id
           LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
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
           LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_variety_id
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
           LEFT JOIN ( SELECT sq.id,
                  COALESCE(btrim(array_agg(orchard_test_types.test_type_code)::text), ''::text) <> ''::text AS failed_otmc,
                  array_agg(orchard_test_types.test_type_code) AS failed_otmc_results
                 FROM pallet_sequences sq
                   JOIN orchard_test_types ON orchard_test_types.id = ANY (sq.failed_otmc_results)
                GROUP BY sq.id) otmc ON otmc.id = ps.id
        ORDER BY ps.pallet_id DESC, ps.pallet_sequence_number;
      
      ALTER TABLE public.vw_pallet_sequence_flat
          OWNER TO postgres;

      -- 6. vw_scrapped_pallet_sequence_flat
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
          scrap_reasons.scrap_reason,
          reworks_runs.remarks AS scrapped_remarks,
          reworks_runs."user" AS scrapped_by
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
           LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_variety_id
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
        ORDER BY p.pallet_number, ps.pallet_sequence_number;
      
      ALTER TABLE public.vw_scrapped_pallet_sequence_flat
          OWNER TO postgres;

      -- 7. vw_repacked_pallet_sequence_flat
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
             LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_variety_id
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
