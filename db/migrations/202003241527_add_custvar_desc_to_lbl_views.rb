Sequel.migration do
  up do
    run <<~SQL
      -- ==========================================================================
      -- Carton label from a carton_labels record
      -- ==========================================================================

      DROP VIEW public.vw_carton_label_lbl;

      CREATE OR REPLACE VIEW public.vw_carton_label_lbl AS
        SELECT "carton_labels"."id" AS carton_label_id,
        "carton_labels"."production_run_id",
        "packhouses"."plant_resource_code" AS packhouse,
        "lines"."plant_resource_code" AS line,
        "carton_labels"."label_name",
        "farms"."farm_code",
        "farm_groups"."farm_group_code",
        "pucs"."puc_code",
        "pucs"."gap_code",
        "orchards"."orchard_code",
        "commodities"."code" AS commodity,
        "commodities"."description" AS commodity_description,
        "cultivar_groups"."cultivar_group_code",
        "cultivar_groups"."description" AS cultivar_group_description,
        "cultivars"."cultivar_name",
        "cultivars"."description" AS cultivar_description,
        "marketing_varieties"."marketing_variety_code",
        "marketing_varieties"."description" AS marketing_variety_description,
        COALESCE("cvv"."marketing_variety_code", "marketing_varieties"."marketing_variety_code") AS customer_or_marketing_variety,
        COALESCE("cvv"."description", "marketing_varieties"."description") AS customer_or_marketing_variety_desc,
        "cvv"."marketing_variety_code" AS customer_variety_code,
        "cvv"."description" AS customer_variety_description,
        "std_fruit_size_counts"."size_count_value",
        "std_fruit_size_counts"."size_count_interval_group",
        uoms.uom_code AS size_count_uom,
        "fruit_size_references"."size_reference",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "basic_pack_codes"."basic_pack_code",
        "standard_pack_codes"."standard_pack_code",
        "standard_pack_codes"."std_pack_label_code",
        "standard_product_weights"."nett_weight" AS pack_nett_weight,
        fn_party_role_name("carton_labels"."marketing_org_party_role_id") AS marketer,
        "marks"."mark_code",
        "inventory_codes"."inventory_code",
        "product_setup_templates"."template_name",
        "pm_boms"."bom_code",
        (SELECT array_agg("clt"."treatment_code")
          FROM (SELECT "t"."treatment_code"
            FROM "treatments" t
            JOIN "carton_labels" cl ON "t"."id" = ANY("cl"."treatment_ids")
            WHERE "cl"."id" = "carton_labels"."id"
            ORDER BY "t"."treatment_code" DESC) clt) AS treatments,
        "carton_labels"."client_size_reference",
        "carton_labels"."client_product_code",
        "carton_labels"."marketing_order_number",
        "target_market_groups"."target_market_group_name" AS packed_tm_group,
        "seasons"."season_code",
        "pm_subtypes"."subtype_code",
        "pm_types"."pm_type_code",
        "cartons_per_pallet"."cartons_per_pallet",
        "pm_products"."product_code",
        "carton_labels"."pallet_number",
        "carton_labels"."sell_by_code",
        "grades"."grade_code",
        "carton_labels"."product_chars",
        "carton_labels"."pick_ref",
        "carton_labels"."phc",
        "lines".resource_properties ->> 'gln' AS gln_code,
        CASE WHEN "commodities"."code" = 'SC' THEN
          CONCAT_WS('/', "fruit_size_references"."size_reference", "std_fruit_size_counts"."size_count_interval_group")
        ELSE
          CONCAT_WS('/', "fruit_size_references"."size_reference", "fruit_actual_counts_for_packs"."actual_count_for_pack")
        END AS count_swap_rule,
        contract_workers.personnel_number

        FROM "carton_labels"
        JOIN "production_runs" ON "production_runs"."id" = "carton_labels"."production_run_id"
        LEFT JOIN "product_resource_allocations" ON "product_resource_allocations"."id" = "carton_labels"."product_resource_allocation_id"
        LEFT JOIN "product_setups" ON "product_setups"."id" = "product_resource_allocations"."product_setup_id"
        LEFT JOIN "product_setup_templates" ON "product_setup_templates"."id" = "product_setups"."product_setup_template_id"
        JOIN "plant_resources" packhouses ON "packhouses"."id" = "carton_labels"."packhouse_resource_id"
        JOIN "plant_resources" lines ON "lines"."id" = "carton_labels"."production_line_id"
        JOIN "farms" ON "farms"."id" = "carton_labels"."farm_id"
        LEFT JOIN "farm_groups" ON "farm_groups"."id" = "farms"."farm_group_id"
        JOIN "pucs" ON "pucs"."id" = "carton_labels"."puc_id"
        JOIN "orchards" ON "orchards"."id" = "carton_labels"."orchard_id"
        JOIN "cultivar_groups" ON "cultivar_groups"."id" = "carton_labels"."cultivar_group_id"
        LEFT JOIN "grades" ON "grades"."id" = "carton_labels"."grade_id"
        LEFT JOIN "cultivars" ON "cultivars"."id" = "carton_labels"."cultivar_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "cultivars"."commodity_id"
        JOIN "marketing_varieties" ON "marketing_varieties"."id" = "carton_labels"."marketing_variety_id"
        LEFT JOIN "customer_variety_varieties" ON "customer_variety_varieties"."id" = "carton_labels"."customer_variety_variety_id"
        LEFT JOIN "marketing_varieties" cvv ON "cvv"."id" = "customer_variety_varieties"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "carton_labels"."std_fruit_size_count_id"
        LEFT JOIN "uoms" ON "uoms"."id" = "std_fruit_size_counts"."uom_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "carton_labels"."fruit_size_reference_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" = "carton_labels"."fruit_actual_counts_for_pack_id"
        JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "carton_labels"."basic_pack_code_id"
        JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "carton_labels"."standard_pack_code_id"
        JOIN "marks" ON "marks"."id" = "carton_labels"."mark_id"
        JOIN "inventory_codes" ON "inventory_codes"."id" = "carton_labels"."inventory_code_id"
        LEFT JOIN "pm_boms" ON "pm_boms"."id" = "carton_labels"."pm_bom_id"
        LEFT JOIN "pm_subtypes" ON "pm_subtypes"."id" = "carton_labels"."pm_subtype_id"
        LEFT JOIN "pm_types" ON "pm_types"."id" = "carton_labels"."pm_type_id"
        JOIN "target_market_groups" ON "target_market_groups"."id" = "carton_labels"."packed_tm_group_id"
        JOIN "seasons" ON "seasons"."id" = "carton_labels"."season_id"
        JOIN "cartons_per_pallet" ON "cartons_per_pallet"."id" = "carton_labels"."cartons_per_pallet_id"
        LEFT JOIN "pm_products" ON "pm_products"."id" = "carton_labels"."fruit_sticker_pm_product_id"
        JOIN "pallet_formats" ON "pallet_formats"."id" = "carton_labels"."pallet_format_id"
        LEFT JOIN "standard_product_weights" ON "standard_product_weights"."commodity_id" = "commodities"."id"
        AND "standard_product_weights"."standard_pack_id" = "carton_labels"."standard_pack_code_id"
        LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id;

      ALTER TABLE public.vw_carton_label_lbl
      OWNER TO postgres;



      -- ==========================================================================
      -- Carton label from a PRODUCT SETUP record
      -- ==========================================================================

      DROP VIEW public.vw_carton_label_pset;

      CREATE OR REPLACE VIEW public.vw_carton_label_pset AS
        SELECT "product_setups"."id" AS carton_label_id,
        "product_resource_allocations"."id" AS product_resource_allocation_id,
        "product_resource_allocations"."production_run_id",
        "packhouses"."plant_resource_code" AS packhouse,
        "lines"."plant_resource_code" AS line,
        "label_templates"."label_template_name" AS label_name,
        "farms"."farm_code",
        "farm_groups"."farm_group_code",
        "pucs"."puc_code",
        "pucs"."gap_code",
        "orchards"."orchard_code",
        "commodities"."code" AS commodity,
        "commodities"."description" AS commodity_description,
        "cultivar_groups"."cultivar_group_code",
        "cultivar_groups"."description" AS cultivar_group_description,
        "cultivars"."cultivar_name",
        "cultivars"."description" AS cultivar_description,
        "marketing_varieties"."marketing_variety_code",
        "marketing_varieties"."description" AS marketing_variety_description,
        COALESCE("cvv"."marketing_variety_code", "marketing_varieties"."marketing_variety_code") AS customer_or_marketing_variety,
        COALESCE("cvv"."description", "marketing_varieties"."description") AS customer_or_marketing_variety_desc,
        "cvv"."marketing_variety_code" AS customer_variety_code,
        "cvv"."description" AS customer_variety_description,
        "std_fruit_size_counts"."size_count_value",
        "std_fruit_size_counts"."size_count_interval_group",
        uoms.uom_code AS size_count_uom,
        "fruit_size_references"."size_reference",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "basic_pack_codes"."basic_pack_code",
        "standard_pack_codes"."standard_pack_code",
        "standard_pack_codes"."std_pack_label_code",
        "standard_product_weights"."nett_weight" AS pack_nett_weight,
        fn_party_role_name("product_setups"."marketing_org_party_role_id") AS marketer,
        "marks"."mark_code",
        "inventory_codes"."inventory_code",
        "product_setup_templates"."template_name",
        "pm_boms"."bom_code",
        (SELECT array_agg("clt"."treatment_code")
          FROM (SELECT "t"."treatment_code"
          FROM "treatments" t
          JOIN "product_setups" cl ON "t"."id" = ANY("cl"."treatment_ids")
          WHERE "cl"."id" = "product_setups"."id"
          ORDER BY "t"."treatment_code" DESC) clt) AS treatments,
        "product_setups"."client_size_reference",
        "product_setups"."client_product_code",
        "product_setups"."marketing_order_number",
        "target_market_groups"."target_market_group_name" AS packed_tm_group,
        "seasons"."season_code",
        'UNK'::text AS subtype_code,
        'UNK'::text AS pm_type_code,
        "cartons_per_pallet"."cartons_per_pallet",
        'UNKNOWN'::text AS product_code,
        'UNKNOWN'::text AS pallet_number,
        "product_setups"."sell_by_code",
        "grades"."grade_code",
        "product_setups"."product_chars",
        substring(to_char(CURRENT_DATE, 'IW') FROM '.$') ||
          extract('dow' FROM CURRENT_DATE)::text ||
          (packhouses.resource_properties ->> 'packhouse_no'::text) ||
          substring(to_char(CURRENT_DATE, 'IW') FROM '.') AS pick_ref,
        COALESCE(lines.resource_properties ->> 'phc', packhouses.resource_properties ->> 'phc') AS phc,
        "lines".resource_properties ->> 'gln' AS gln_code,
        CASE WHEN "commodities"."code" = 'SC' THEN
          CONCAT_WS('/', "fruit_size_references"."size_reference", "std_fruit_size_counts"."size_count_interval_group")
        ELSE
          CONCAT_WS('/', "fruit_size_references"."size_reference", "fruit_actual_counts_for_packs"."actual_count_for_pack")
        END AS count_swap_rule,
        'UNK'::text AS personnel_number

        FROM "product_resource_allocations"
        JOIN "production_runs" ON "production_runs"."id" = "product_resource_allocations"."production_run_id"
        JOIN "product_setups" ON "product_setups"."id" = "product_resource_allocations"."product_setup_id"
        JOIN "product_setup_templates" ON "product_setup_templates"."id" = "product_setups"."product_setup_template_id"
        JOIN "plant_resources" packhouses ON "packhouses"."id" = "production_runs"."packhouse_resource_id"
        JOIN "plant_resources" lines ON "lines"."id" = "production_runs"."production_line_id"
        LEFT JOIN "label_templates" ON "label_templates"."id" = "product_resource_allocations"."label_template_id"
        JOIN "farms" ON "farms"."id" = "production_runs"."farm_id"
        LEFT JOIN "farm_groups" ON "farm_groups"."id" = "farms"."farm_group_id"
        JOIN "pucs" ON "pucs"."id" = "production_runs"."puc_id"
        JOIN "orchards" ON "orchards"."id" = "production_runs"."orchard_id"
        JOIN "cultivar_groups" ON "cultivar_groups"."id" = "production_runs"."cultivar_group_id"
        LEFT JOIN "grades" ON "grades"."id" = "product_setups"."grade_id"
        LEFT JOIN "cultivars" ON "cultivars"."id" = "production_runs"."cultivar_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "cultivars"."commodity_id"
        JOIN "marketing_varieties" ON "marketing_varieties"."id" = "product_setups"."marketing_variety_id"
        LEFT JOIN "customer_variety_varieties" ON "customer_variety_varieties"."id" = "product_setups"."customer_variety_variety_id"
        LEFT JOIN "marketing_varieties" cvv ON "cvv"."id" = "customer_variety_varieties"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "product_setups"."std_fruit_size_count_id"
        LEFT JOIN "uoms" ON "uoms"."id" = "std_fruit_size_counts"."uom_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "product_setups"."fruit_size_reference_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" = "product_setups"."fruit_actual_counts_for_pack_id"
        JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "product_setups"."basic_pack_code_id"
        JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "product_setups"."standard_pack_code_id"
        JOIN "marks" ON "marks"."id" = "product_setups"."mark_id"
        JOIN "inventory_codes" ON "inventory_codes"."id" = "product_setups"."inventory_code_id"
        LEFT JOIN "pm_boms" ON "pm_boms"."id" = "product_setups"."pm_bom_id"
        JOIN "target_market_groups" ON "target_market_groups"."id" = "product_setups"."packed_tm_group_id"
        JOIN "seasons" ON "seasons"."id" = "production_runs"."season_id"
        JOIN "cartons_per_pallet" ON "cartons_per_pallet"."id" = "product_setups"."cartons_per_pallet_id"
        JOIN "pallet_formats" ON "pallet_formats"."id" = "product_setups"."pallet_format_id"
        LEFT JOIN "standard_product_weights" ON "standard_product_weights"."commodity_id" = "commodities"."id"
          AND "standard_product_weights"."standard_pack_id" = "product_setups"."standard_pack_code_id";

      ALTER TABLE public.vw_carton_label_pset
      OWNER TO postgres;




      -- ==========================================================================
      -- Carton label from a pallet sequence record
      -- ==========================================================================

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
        "cvv"."description" AS customer_variety_description,
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

  down do
    run <<~SQL
      -- ==========================================================================
      -- Carton label from a carton_labels record
      -- ==========================================================================

      DROP VIEW public.vw_carton_label_lbl;

      CREATE OR REPLACE VIEW public.vw_carton_label_lbl AS
        SELECT "carton_labels"."id" AS carton_label_id,
        "carton_labels"."production_run_id",
        "packhouses"."plant_resource_code" AS packhouse,
        "lines"."plant_resource_code" AS line,
        "carton_labels"."label_name",
        "farms"."farm_code",
        "farm_groups"."farm_group_code",
        "pucs"."puc_code",
        "pucs"."gap_code",
        "orchards"."orchard_code",
        "commodities"."code" AS commodity,
        "commodities"."description" AS commodity_description,
        "cultivar_groups"."cultivar_group_code",
        "cultivar_groups"."description" AS cultivar_group_description,
        "cultivars"."cultivar_name",
        "cultivars"."description" AS cultivar_description,
        "marketing_varieties"."marketing_variety_code",
        "marketing_varieties"."description" AS marketing_variety_description,
        COALESCE("cvv"."marketing_variety_code", "marketing_varieties"."marketing_variety_code") AS customer_or_marketing_variety,
        COALESCE("cvv"."description", "marketing_varieties"."description") AS customer_or_marketing_variety_desc,
        "cvv"."marketing_variety_code" AS customer_variety_code,
        "std_fruit_size_counts"."size_count_value",
        "std_fruit_size_counts"."size_count_interval_group",
        uoms.uom_code AS size_count_uom,
        "fruit_size_references"."size_reference",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "basic_pack_codes"."basic_pack_code",
        "standard_pack_codes"."standard_pack_code",
        "standard_pack_codes"."std_pack_label_code",
        "standard_product_weights"."nett_weight" AS pack_nett_weight,
        fn_party_role_name("carton_labels"."marketing_org_party_role_id") AS marketer,
        "marks"."mark_code",
        "inventory_codes"."inventory_code",
        "product_setup_templates"."template_name",
        "pm_boms"."bom_code",
        (SELECT array_agg("clt"."treatment_code")
          FROM (SELECT "t"."treatment_code"
            FROM "treatments" t
            JOIN "carton_labels" cl ON "t"."id" = ANY("cl"."treatment_ids")
            WHERE "cl"."id" = "carton_labels"."id"
            ORDER BY "t"."treatment_code" DESC) clt) AS treatments,
        "carton_labels"."client_size_reference",
        "carton_labels"."client_product_code",
        "carton_labels"."marketing_order_number",
        "target_market_groups"."target_market_group_name" AS packed_tm_group,
        "seasons"."season_code",
        "pm_subtypes"."subtype_code",
        "pm_types"."pm_type_code",
        "cartons_per_pallet"."cartons_per_pallet",
        "pm_products"."product_code",
        "carton_labels"."pallet_number",
        "carton_labels"."sell_by_code",
        "grades"."grade_code",
        "carton_labels"."product_chars",
        "carton_labels"."pick_ref",
        "carton_labels"."phc",
        "lines".resource_properties ->> 'gln' AS gln_code,
        CASE WHEN "commodities"."code" = 'SC' THEN
          CONCAT_WS('/', "fruit_size_references"."size_reference", "std_fruit_size_counts"."size_count_interval_group")
        ELSE
          CONCAT_WS('/', "fruit_size_references"."size_reference", "fruit_actual_counts_for_packs"."actual_count_for_pack")
        END AS count_swap_rule,
        contract_workers.personnel_number

        FROM "carton_labels"
        JOIN "production_runs" ON "production_runs"."id" = "carton_labels"."production_run_id"
        LEFT JOIN "product_resource_allocations" ON "product_resource_allocations"."id" = "carton_labels"."product_resource_allocation_id"
        LEFT JOIN "product_setups" ON "product_setups"."id" = "product_resource_allocations"."product_setup_id"
        LEFT JOIN "product_setup_templates" ON "product_setup_templates"."id" = "product_setups"."product_setup_template_id"
        JOIN "plant_resources" packhouses ON "packhouses"."id" = "carton_labels"."packhouse_resource_id"
        JOIN "plant_resources" lines ON "lines"."id" = "carton_labels"."production_line_id"
        JOIN "farms" ON "farms"."id" = "carton_labels"."farm_id"
        LEFT JOIN "farm_groups" ON "farm_groups"."id" = "farms"."farm_group_id"
        JOIN "pucs" ON "pucs"."id" = "carton_labels"."puc_id"
        JOIN "orchards" ON "orchards"."id" = "carton_labels"."orchard_id"
        JOIN "cultivar_groups" ON "cultivar_groups"."id" = "carton_labels"."cultivar_group_id"
        LEFT JOIN "grades" ON "grades"."id" = "carton_labels"."grade_id"
        LEFT JOIN "cultivars" ON "cultivars"."id" = "carton_labels"."cultivar_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "cultivars"."commodity_id"
        JOIN "marketing_varieties" ON "marketing_varieties"."id" = "carton_labels"."marketing_variety_id"
        LEFT JOIN "customer_variety_varieties" ON "customer_variety_varieties"."id" = "carton_labels"."customer_variety_variety_id"
        LEFT JOIN "marketing_varieties" cvv ON "cvv"."id" = "customer_variety_varieties"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "carton_labels"."std_fruit_size_count_id"
        LEFT JOIN "uoms" ON "uoms"."id" = "std_fruit_size_counts"."uom_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "carton_labels"."fruit_size_reference_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" = "carton_labels"."fruit_actual_counts_for_pack_id"
        JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "carton_labels"."basic_pack_code_id"
        JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "carton_labels"."standard_pack_code_id"
        JOIN "marks" ON "marks"."id" = "carton_labels"."mark_id"
        JOIN "inventory_codes" ON "inventory_codes"."id" = "carton_labels"."inventory_code_id"
        LEFT JOIN "pm_boms" ON "pm_boms"."id" = "carton_labels"."pm_bom_id"
        LEFT JOIN "pm_subtypes" ON "pm_subtypes"."id" = "carton_labels"."pm_subtype_id"
        LEFT JOIN "pm_types" ON "pm_types"."id" = "carton_labels"."pm_type_id"
        JOIN "target_market_groups" ON "target_market_groups"."id" = "carton_labels"."packed_tm_group_id"
        JOIN "seasons" ON "seasons"."id" = "carton_labels"."season_id"
        JOIN "cartons_per_pallet" ON "cartons_per_pallet"."id" = "carton_labels"."cartons_per_pallet_id"
        LEFT JOIN "pm_products" ON "pm_products"."id" = "carton_labels"."fruit_sticker_pm_product_id"
        JOIN "pallet_formats" ON "pallet_formats"."id" = "carton_labels"."pallet_format_id"
        LEFT JOIN "standard_product_weights" ON "standard_product_weights"."commodity_id" = "commodities"."id"
        AND "standard_product_weights"."standard_pack_id" = "carton_labels"."standard_pack_code_id"
        LEFT JOIN contract_workers ON contract_workers.id = carton_labels.contract_worker_id;

      ALTER TABLE public.vw_carton_label_lbl
      OWNER TO postgres;



      -- ==========================================================================
      -- Carton label from a PRODUCT SETUP record
      -- ==========================================================================

      DROP VIEW public.vw_carton_label_pset;

      CREATE OR REPLACE VIEW public.vw_carton_label_pset AS
        SELECT "product_setups"."id" AS carton_label_id,
        "product_resource_allocations"."id" AS product_resource_allocation_id,
        "product_resource_allocations"."production_run_id",
        "packhouses"."plant_resource_code" AS packhouse,
        "lines"."plant_resource_code" AS line,
        "label_templates"."label_template_name" AS label_name,
        "farms"."farm_code",
        "farm_groups"."farm_group_code",
        "pucs"."puc_code",
        "pucs"."gap_code",
        "orchards"."orchard_code",
        "commodities"."code" AS commodity,
        "commodities"."description" AS commodity_description,
        "cultivar_groups"."cultivar_group_code",
        "cultivar_groups"."description" AS cultivar_group_description,
        "cultivars"."cultivar_name",
        "cultivars"."description" AS cultivar_description,
        "marketing_varieties"."marketing_variety_code",
        "marketing_varieties"."description" AS marketing_variety_description,
        COALESCE("cvv"."marketing_variety_code", "marketing_varieties"."marketing_variety_code") AS customer_or_marketing_variety,
        COALESCE("cvv"."description", "marketing_varieties"."description") AS customer_or_marketing_variety_desc,
        "cvv"."marketing_variety_code" AS customer_variety_code,
        "std_fruit_size_counts"."size_count_value",
        "std_fruit_size_counts"."size_count_interval_group",
        uoms.uom_code AS size_count_uom,
        "fruit_size_references"."size_reference",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "basic_pack_codes"."basic_pack_code",
        "standard_pack_codes"."standard_pack_code",
        "standard_pack_codes"."std_pack_label_code",
        "standard_product_weights"."nett_weight" AS pack_nett_weight,
        fn_party_role_name("product_setups"."marketing_org_party_role_id") AS marketer,
        "marks"."mark_code",
        "inventory_codes"."inventory_code",
        "product_setup_templates"."template_name",
        "pm_boms"."bom_code",
        (SELECT array_agg("clt"."treatment_code")
          FROM (SELECT "t"."treatment_code"
          FROM "treatments" t
          JOIN "product_setups" cl ON "t"."id" = ANY("cl"."treatment_ids")
          WHERE "cl"."id" = "product_setups"."id"
          ORDER BY "t"."treatment_code" DESC) clt) AS treatments,
        "product_setups"."client_size_reference",
        "product_setups"."client_product_code",
        "product_setups"."marketing_order_number",
        "target_market_groups"."target_market_group_name" AS packed_tm_group,
        "seasons"."season_code",
        'UNK'::text AS subtype_code,
        'UNK'::text AS pm_type_code,
        "cartons_per_pallet"."cartons_per_pallet",
        'UNKNOWN'::text AS product_code,
        'UNKNOWN'::text AS pallet_number,
        "product_setups"."sell_by_code",
        "grades"."grade_code",
        "product_setups"."product_chars",
        substring(to_char(CURRENT_DATE, 'IW') FROM '.$') ||
          extract('dow' FROM CURRENT_DATE)::text ||
          (packhouses.resource_properties ->> 'packhouse_no'::text) ||
          substring(to_char(CURRENT_DATE, 'IW') FROM '.') AS pick_ref,
        COALESCE(lines.resource_properties ->> 'phc', packhouses.resource_properties ->> 'phc') AS phc,
        "lines".resource_properties ->> 'gln' AS gln_code,
        CASE WHEN "commodities"."code" = 'SC' THEN
          CONCAT_WS('/', "fruit_size_references"."size_reference", "std_fruit_size_counts"."size_count_interval_group")
        ELSE
          CONCAT_WS('/', "fruit_size_references"."size_reference", "fruit_actual_counts_for_packs"."actual_count_for_pack")
        END AS count_swap_rule,
        'UNK'::text AS personnel_number

        FROM "product_resource_allocations"
        JOIN "production_runs" ON "production_runs"."id" = "product_resource_allocations"."production_run_id"
        JOIN "product_setups" ON "product_setups"."id" = "product_resource_allocations"."product_setup_id"
        JOIN "product_setup_templates" ON "product_setup_templates"."id" = "product_setups"."product_setup_template_id"
        JOIN "plant_resources" packhouses ON "packhouses"."id" = "production_runs"."packhouse_resource_id"
        JOIN "plant_resources" lines ON "lines"."id" = "production_runs"."production_line_id"
        LEFT JOIN "label_templates" ON "label_templates"."id" = "product_resource_allocations"."label_template_id"
        JOIN "farms" ON "farms"."id" = "production_runs"."farm_id"
        LEFT JOIN "farm_groups" ON "farm_groups"."id" = "farms"."farm_group_id"
        JOIN "pucs" ON "pucs"."id" = "production_runs"."puc_id"
        JOIN "orchards" ON "orchards"."id" = "production_runs"."orchard_id"
        JOIN "cultivar_groups" ON "cultivar_groups"."id" = "production_runs"."cultivar_group_id"
        LEFT JOIN "grades" ON "grades"."id" = "product_setups"."grade_id"
        LEFT JOIN "cultivars" ON "cultivars"."id" = "production_runs"."cultivar_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "cultivars"."commodity_id"
        JOIN "marketing_varieties" ON "marketing_varieties"."id" = "product_setups"."marketing_variety_id"
        LEFT JOIN "customer_variety_varieties" ON "customer_variety_varieties"."id" = "product_setups"."customer_variety_variety_id"
        LEFT JOIN "marketing_varieties" cvv ON "cvv"."id" = "customer_variety_varieties"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "product_setups"."std_fruit_size_count_id"
        LEFT JOIN "uoms" ON "uoms"."id" = "std_fruit_size_counts"."uom_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "product_setups"."fruit_size_reference_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" = "product_setups"."fruit_actual_counts_for_pack_id"
        JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "product_setups"."basic_pack_code_id"
        JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "product_setups"."standard_pack_code_id"
        JOIN "marks" ON "marks"."id" = "product_setups"."mark_id"
        JOIN "inventory_codes" ON "inventory_codes"."id" = "product_setups"."inventory_code_id"
        LEFT JOIN "pm_boms" ON "pm_boms"."id" = "product_setups"."pm_bom_id"
        JOIN "target_market_groups" ON "target_market_groups"."id" = "product_setups"."packed_tm_group_id"
        JOIN "seasons" ON "seasons"."id" = "production_runs"."season_id"
        JOIN "cartons_per_pallet" ON "cartons_per_pallet"."id" = "product_setups"."cartons_per_pallet_id"
        JOIN "pallet_formats" ON "pallet_formats"."id" = "product_setups"."pallet_format_id"
        LEFT JOIN "standard_product_weights" ON "standard_product_weights"."commodity_id" = "commodities"."id"
          AND "standard_product_weights"."standard_pack_id" = "product_setups"."standard_pack_code_id";

      ALTER TABLE public.vw_carton_label_pset
      OWNER TO postgres;




      -- ==========================================================================
      -- Carton label from a pallet sequence record
      -- ==========================================================================

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
                contract_workers.personnel_number
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
