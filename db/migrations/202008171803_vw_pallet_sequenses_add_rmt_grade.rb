Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
    SQL
    run <<~SQL
    CREATE VIEW public.vw_pallet_sequences AS
      SELECT
        ps.id AS pallet_sequence_id,
        fn_current_status ('pallet_sequences', ps.id) AS sequence_status,
        ps.pallet_id,
        ps.pallet_number,
        ps.pallet_sequence_number,
        --
        ps.created_at AS packed_at,
        ps.created_at::date AS packed_date,
        EXTRACT(WEEK FROM ps.created_at) AS packed_week,
        --
        ps.production_run_id,
        --
        ps.season_id,
        seasons.season_code,
        --
        ps.farm_id,
        farms.farm_code,
        farm_groups.farm_group_code,
        production_regions.production_region_code,
        --
        ps.puc_id,
        pucs.puc_code,
        --
        ps.orchard_id,
        orchards.orchard_code,
        commodities.code AS commodity_code,
        --
        ps.cultivar_group_id,
        cultivar_groups.cultivar_group_code,
        --
        ps.cultivar_id,
        cultivars.cultivar_name,
        cultivars.cultivar_code,
        --
        ps.product_resource_allocation_id AS resource_allocation_id,
        --
        ps.packhouse_resource_id,
        packhouses.plant_resource_code AS packhouse_code,
        --
        ps.production_line_id,
        lines.plant_resource_code AS line_code,
        --
        ps.marketing_variety_id,
        marketing_varieties.marketing_variety_code,
        --
        ps.customer_variety_id,
        customer_varieties.variety_as_customer_variety_id,
        customer_marketing_varieties.marketing_variety_code AS customer_marketing_variety_code,
        --
        ps.std_fruit_size_count_id,
        std_fruit_size_counts.size_count_value AS standard_size,
        std_fruit_size_counts.size_count_interval_group AS count_group,
        ROUND((ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9, 5),2) AS standard_count,
        --
        ps.basic_pack_code_id,
        basic_pack_codes.basic_pack_code,
        --
        ps.standard_pack_code_id,
        standard_pack_codes.standard_pack_code,
        --
        ps.fruit_actual_counts_for_pack_id,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        --
        fn_edi_size_count (standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
        --
        ps.fruit_size_reference_id,
        fruit_size_references.size_reference AS size_ref,
        --
        ps.marketing_org_party_role_id,
        fn_party_role_name (ps.marketing_org_party_role_id) AS marketing_org,
        --
        ps.packed_tm_group_id,
        target_market_groups.target_market_group_name AS packed_tm_group,
        --
        ps.mark_id,
        marks.mark_code AS mark,
        --
        ps.inventory_code_id,
        inventory_codes.inventory_code,
        --
        ps.pallet_format_id,
        pallet_formats.description AS pallet_format,
        --
        ps.cartons_per_pallet_id,
        cartons_per_pallet.cartons_per_pallet,
        --
        ps.pm_bom_id,
        pm_boms.bom_code,
        --
        ps.extended_columns,
        ps.client_size_reference,
        ps.client_product_code,
        --
        ps.treatment_ids,
        (select array_agg(distinct treatments.treatment_code)
         from treatments 
         where treatments.id = ANY (ps.treatment_ids)
         group by ps.id) AS treatment_codes,
        --
        ps.marketing_order_number,
        --
        ps.pm_type_id,
        pm_types.pm_type_code,
        --
        ps.pm_subtype_id,
        pm_subtypes.subtype_code,
        --
        ps.carton_quantity AS sequence_carton_quantity,
        --
        ps.scanned_from_carton_id AS scanned_carton,
        --
        ps.scrapped_at AS seq_scrapped_at,
        ps.exit_ref AS seq_exit_ref,
        --
        ps.verification_result,
        --
        ps.pallet_verification_failure_reason_id,
        pallet_verification_failure_reasons.reason AS verification_failure_reason,
        --
        ps.verified,
        ps.verified_by,
        ps.verified_at,
        ps.verification_passed,
        --
        ROUND(ps.nett_weight,2) AS sequence_nett_weight,
        --
        ps.pick_ref,
        --
        ps.grade_id,
        grades.grade_code,
        grades.rmt_grade,
        --
        ps.scrapped_from_pallet_id,
        ps.removed_from_pallet,
        ps.removed_from_pallet_id,
        ps.removed_from_pallet_at,
        ps.sell_by_code,
        ps.product_chars,
        ps.depot_pallet,
        --
        ps.personnel_identifier_id,
        personnel_identifiers.hardware_type,
        personnel_identifiers.identifier,
        --
        ps.contract_worker_id,
        --
        ps.repacked_at IS NOT NULL AS sequence_repacked,
        ps.repacked_at AS sequence_repacked_at,
        ps.repacked_from_pallet_id,
        --
        ps.failed_otmc_results IS NOT NULL AS failed_otmc,
        ps.failed_otmc_results AS failed_otmc_result_ids,
        (select
             array_agg(distinct orchard_test_types.test_type_code order by orchard_test_types.test_type_code)
         from
             orchard_test_types
         where orchard_test_types.id = ANY (ps.failed_otmc_results)
         group by ps.id) AS failed_otmc_results,
        ps.phyto_data,
        --
        ps.active,
        ps.created_by,
        ps.created_at,
        ps.updated_at
        
      FROM pallet_sequences ps
      JOIN seasons ON seasons.id = ps.season_id
      --
      JOIN farms ON farms.id = ps.farm_id
      LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
      LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
      --
      JOIN pucs ON pucs.id = ps.puc_id
      --
      JOIN orchards ON orchards.id = ps.orchard_id
      --
      JOIN cultivars ON cultivars.id = ps.cultivar_id
      --
      JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
      LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
      --
      LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
      --
      LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
      --
      JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
      --
      LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
      LEFT JOIN marketing_varieties customer_marketing_varieties ON customer_marketing_varieties.id = customer_varieties.variety_as_customer_variety_id
      --
      JOIN marks ON marks.id = ps.mark_id
      --
      JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
      --
      JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
      --
      JOIN grades ON grades.id = ps.grade_id
      --
      LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
      --
      LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
      --
      LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
      --
      JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
      --
      JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
      --
      LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
      --
      LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
      --
      LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
      --
      JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
      --
      LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
      --
      LEFT JOIN personnel_identifiers ON  personnel_identifiers.id = ps.personnel_identifier_id
      --
      LEFT JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
      WHERE
        ps.pallet_id IS NOT NULL;
    ALTER TABLE public.vw_pallet_sequences OWNER TO postgres;
    SQL

    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences_aggregated AS
        SELECT
            pallet_id,
            pallet_number,
            array_agg(distinct pallet_sequence_id) pallet_sequence_ids,
            string_agg(distinct sequence_status::text, ', ') sequence_statuses,
            string_agg(distinct pallet_sequence_number::text, ', ') pallet_sequence_numbers,
            string_agg(distinct packed_at::text, ', ') packed_at,
            string_agg(distinct packed_date::text, ', ') packed_dates,
            string_agg(distinct packed_week::text, ', ') packed_weeks,
            array_agg(distinct production_run_id) production_run_ids,
            array_agg(distinct season_id) season_ids,
            string_agg(distinct season_code::text, ', ') season_codes,
            array_agg(distinct farm_id) farm_ids,
            string_agg(distinct farm_code::text, ', ') farm_codes,
            string_agg(distinct farm_group_code::text, ', ') farm_group_codes,
            string_agg(distinct production_region_code::text, ', ') production_region_codes,
            array_agg(distinct puc_id) puc_ids,
            string_agg(distinct puc_code::text, ', ') puc_codes,
            array_agg(distinct orchard_id) orchard_ids,
            string_agg(distinct orchard_code::text, ', ') orchard_codes,
            string_agg(distinct commodity_code::text, ', ') commodity_codes,
            array_agg(distinct cultivar_group_id) cultivar_group_ids,
            string_agg(distinct cultivar_group_code::text, ', ') cultivar_group_codes,
            array_agg(distinct cultivar_id) cultivar_ids,
            string_agg(distinct cultivar_name::text, ', ') cultivar_names,
            string_agg(distinct cultivar_code::text, ', ') cultivar_codes,
            array_agg(distinct resource_allocation_id) resource_allocation_ids,
            array_agg(distinct packhouse_resource_id) packhouse_resource_ids,
            string_agg(distinct packhouse_code::text, ', ') packhouse_codes,
            array_agg(distinct production_line_id) production_line_ids,
            string_agg(distinct line_code::text, ', ') line_codes,
            array_agg(distinct marketing_variety_id) marketing_variety_ids,
            string_agg(distinct marketing_variety_code::text, ', ') marketing_variety_codes,
            array_agg(distinct customer_variety_id) customer_variety_ids,
            array_agg(distinct variety_as_customer_variety_id) variety_as_customer_variety_ids,
            string_agg(distinct customer_marketing_variety_code::text, ', ') customer_marketing_variety_codes,
            array_agg(distinct std_fruit_size_count_id) std_fruit_size_count_ids,
            string_agg(distinct standard_size::text, ', ') standard_sizes,
            string_agg(distinct count_group::text, ', ') count_groups,
            string_agg(distinct standard_count::text, ', ') standard_counts,
            array_agg(distinct basic_pack_code_id) basic_pack_code_ids,
            string_agg(distinct basic_pack_code::text, ', ') basic_pack_codes,
            array_agg(distinct standard_pack_code_id) standard_pack_code_ids,
            string_agg(distinct standard_pack_code::text, ', ') standard_pack_codes,
            array_agg(distinct fruit_actual_counts_for_pack_id) fruit_actual_counts_for_pack_ids,
            string_agg(distinct actual_count::text, ', ') actual_counts,
            string_agg(distinct edi_size_count::text, ', ') edi_size_counts,
            array_agg(distinct fruit_size_reference_id) fruit_size_reference_ids,
            string_agg(distinct size_ref::text, ', ') size_refs,
            array_agg(distinct marketing_org_party_role_id) marketing_org_party_role_ids,
            string_agg(distinct marketing_org::text, ', ') marketing_orgs,
            array_agg(distinct packed_tm_group_id) packed_tm_group_ids,
            string_agg(distinct packed_tm_group::text, ', ') packed_tm_groups,
            array_agg(distinct mark_id) mark_ids,
            string_agg(distinct mark::text, ', ') marks,
            array_agg(distinct inventory_code_id) inventory_code_ids,
            string_agg(distinct inventory_code::text, ', ') inventory_codes,
            array_agg(distinct pallet_format_id) pallet_format_ids,
            string_agg(distinct pallet_format::text, ', ') pallet_formats,
            array_agg(distinct cartons_per_pallet_id) cartons_per_pallet_ids,
            string_agg(distinct cartons_per_pallet::text, ', ') cartons_per_pallets,
            array_agg(distinct pm_bom_id) pm_bom_ids,
            string_agg(distinct bom_code::text, ', ') bom_codes,
            string_agg(distinct extended_columns::text, ', ') extended_columns,
            string_agg(distinct client_size_reference::text, ', ') client_size_references,
            string_agg(distinct client_product_code::text, ', ') client_product_codes,
            --
            array_agg(distinct treatment_id) treatment_ids,
            string_agg(distinct treatment_code::text, ', ') treatment_codes,
            --
            string_agg(distinct marketing_order_number::text, ', ') marketing_order_numbers,
            array_agg(distinct pm_type_id) pm_type_ids,
            string_agg(distinct pm_type_code::text, ', ') pm_type_codes,
            array_agg(distinct pm_subtype_id) pm_subtype_ids,
            string_agg(distinct subtype_code::text, ', ') subtype_codes,
            string_agg(distinct sequence_carton_quantity::text, ', ') sequence_carton_quantity,
            string_agg(distinct scanned_carton::text, ', ') scanned_cartons,
            string_agg(distinct seq_scrapped_at::text, ', ') seq_scrapped_at,
            string_agg(distinct seq_exit_ref::text, ', ') seq_exit_refs,
            string_agg(distinct verification_result::text, ', ') verification_results,
            array_agg(distinct pallet_verification_failure_reason_id) pallet_verification_failure_reason_ids,
            string_agg(distinct verification_failure_reason::text, ', ') verification_failure_reasons,
            bool_and(verified) verified,
            string_agg(distinct verified_by::text, ', ') verified_by,
            string_agg(distinct verified_at::text, ', ') verified_at,
            bool_and(verification_passed) verifications_passed,
            string_agg(distinct pick_ref::text, ', ') pick_refs,
            array_agg(distinct grade_id) grade_ids,
            string_agg(distinct grade_code::text, ', ') grade_codes,
            bool_and(rmt_grade) rmt_grades,
            array_agg(distinct scrapped_from_pallet_id) scrapped_from_pallet_ids,
            bool_and(removed_from_pallet) removed_from_pallets,
            array_agg(distinct removed_from_pallet_id) removed_from_pallet_ids,
            string_agg(distinct removed_from_pallet_at::text, ', ') removed_from_pallet_at,
            string_agg(distinct sell_by_code::text, ', ') sell_by_codes,
            string_agg(distinct product_chars::text, ', ') product_chars,
            bool_and(depot_pallet) depot_pallets,
            array_agg(distinct personnel_identifier_id) personnel_identifier_ids,
            string_agg(distinct hardware_type::text, ', ') hardware_types,
            string_agg(distinct identifier::text, ', ') identifiers,
            array_agg(distinct contract_worker_id) contract_worker_ids,
            bool_and(sequence_repacked) sequence_repacked,
            string_agg(distinct sequence_repacked_at::text, ', ') sequence_repacked_at,
            array_agg(distinct repacked_from_pallet_id)  repacked_from_pallet_ids,
            --
            bool_and(failed_otmc) failed_otmc,
            array_agg(distinct failed_otmc_result_id) failed_otmc_result_ids,
            string_agg(distinct failed_otmc_result::text, ', ') failed_otmc_results,
            string_agg(distinct phyto_data::text, ', ') phyto_data,
            --
            bool_and(active) active,
            string_agg(distinct created_by::text, ', ') created_by,
            string_agg(distinct created_at::text, ', ') created_at,
            string_agg(distinct updated_at::text, ', ') updated_at
        FROM vw_pallet_sequences,
             UNNEST(CASE WHEN failed_otmc_result_ids <> '{}' THEN failed_otmc_result_ids ELSE '{null}' END) AS failed_otmc_result_id,
             UNNEST(CASE WHEN failed_otmc_results <> '{}' THEN failed_otmc_results ELSE '{null}' END) AS failed_otmc_result,
             UNNEST(CASE WHEN treatment_ids <> '{}' THEN treatment_ids ELSE '{null}' END) AS treatment_id,
             UNNEST(CASE WHEN treatment_codes <> '{}' THEN treatment_codes ELSE '{null}' END) AS treatment_code
        GROUP BY
            pallet_id,
            pallet_number;

      ALTER TABLE public.vw_pallet_sequences_aggregated OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
    SQL

    run <<~SQL
    CREATE VIEW public.vw_pallet_sequences AS
      SELECT
        ps.id AS pallet_sequence_id,
        fn_current_status ('pallet_sequences', ps.id) AS sequence_status,
        ps.pallet_id,
        ps.pallet_number,
        ps.pallet_sequence_number,
        --
        ps.created_at AS packed_at,
        ps.created_at::date AS packed_date,
        EXTRACT(WEEK FROM ps.created_at) AS packed_week,
        --
        ps.production_run_id,
        --
        ps.season_id,
        seasons.season_code,
        --
        ps.farm_id,
        farms.farm_code,
        farm_groups.farm_group_code,
        production_regions.production_region_code,
        --
        ps.puc_id,
        pucs.puc_code,
        --
        ps.orchard_id,
        orchards.orchard_code,
        commodities.code AS commodity_code,
        --
        ps.cultivar_group_id,
        cultivar_groups.cultivar_group_code,
        --
        ps.cultivar_id,
        cultivars.cultivar_name,
        cultivars.cultivar_code,
        --
        ps.product_resource_allocation_id AS resource_allocation_id,
        --
        ps.packhouse_resource_id,
        packhouses.plant_resource_code AS packhouse_code,
        --
        ps.production_line_id,
        lines.plant_resource_code AS line_code,
        --
        ps.marketing_variety_id,
        marketing_varieties.marketing_variety_code,
        --
        ps.customer_variety_id,
        customer_varieties.variety_as_customer_variety_id,
        customer_marketing_varieties.marketing_variety_code AS customer_marketing_variety_code,
        --
        ps.std_fruit_size_count_id,
        std_fruit_size_counts.size_count_value AS standard_size,
        std_fruit_size_counts.size_count_interval_group AS count_group,
        ROUND((ps.carton_quantity * fruit_actual_counts_for_packs.actual_count_for_pack)::numeric / std_fruit_size_counts.size_count_value::numeric(9, 5),2) AS standard_count,
        --
        ps.basic_pack_code_id,
        basic_pack_codes.basic_pack_code,
        --
        ps.standard_pack_code_id,
        standard_pack_codes.standard_pack_code,
        --
        ps.fruit_actual_counts_for_pack_id,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        --
        fn_edi_size_count (standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
        --
        ps.fruit_size_reference_id,
        fruit_size_references.size_reference AS size_ref,
        --
        ps.marketing_org_party_role_id,
        fn_party_role_name (ps.marketing_org_party_role_id) AS marketing_org,
        --
        ps.packed_tm_group_id,
        target_market_groups.target_market_group_name AS packed_tm_group,
        --
        ps.mark_id,
        marks.mark_code AS mark,
        --
        ps.inventory_code_id,
        inventory_codes.inventory_code,
        --
        ps.pallet_format_id,
        pallet_formats.description AS pallet_format,
        --
        ps.cartons_per_pallet_id,
        cartons_per_pallet.cartons_per_pallet,
        --
        ps.pm_bom_id,
        pm_boms.bom_code,
        --
        ps.extended_columns,
        ps.client_size_reference,
        ps.client_product_code,
        --
        ps.treatment_ids,
        (select array_agg(distinct treatments.treatment_code)
         from treatments 
         where treatments.id = ANY (ps.treatment_ids)
         group by ps.id) AS treatment_codes,
        --
        ps.marketing_order_number,
        --
        ps.pm_type_id,
        pm_types.pm_type_code,
        --
        ps.pm_subtype_id,
        pm_subtypes.subtype_code,
        --
        ps.carton_quantity AS sequence_carton_quantity,
        --
        ps.scanned_from_carton_id AS scanned_carton,
        --
        ps.scrapped_at AS seq_scrapped_at,
        ps.exit_ref AS seq_exit_ref,
        --
        ps.verification_result,
        --
        ps.pallet_verification_failure_reason_id,
        pallet_verification_failure_reasons.reason AS verification_failure_reason,
        --
        ps.verified,
        ps.verified_by,
        ps.verified_at,
        ps.verification_passed,
        --
        ROUND(ps.nett_weight,2) AS sequence_nett_weight,
        --
        ps.pick_ref,
        --
        ps.grade_id,
        grades.grade_code,
        --
        ps.scrapped_from_pallet_id,
        ps.removed_from_pallet,
        ps.removed_from_pallet_id,
        ps.removed_from_pallet_at,
        ps.sell_by_code,
        ps.product_chars,
        ps.depot_pallet,
        --
        ps.personnel_identifier_id,
        personnel_identifiers.hardware_type,
        personnel_identifiers.identifier,
        --
        ps.contract_worker_id,
        --
        ps.repacked_at IS NOT NULL AS sequence_repacked,
        ps.repacked_at AS sequence_repacked_at,
        ps.repacked_from_pallet_id,
        --
        ps.failed_otmc_results IS NOT NULL AS failed_otmc,
        ps.failed_otmc_results AS failed_otmc_result_ids,
        (select
             array_agg(distinct orchard_test_types.test_type_code order by orchard_test_types.test_type_code)
         from
             orchard_test_types
         where orchard_test_types.id = ANY (ps.failed_otmc_results)
         group by ps.id) AS failed_otmc_results,
        ps.phyto_data,
        --
        ps.active,
        ps.created_by,
        ps.created_at,
        ps.updated_at
        
      FROM pallet_sequences ps
      JOIN seasons ON seasons.id = ps.season_id
      --
      JOIN farms ON farms.id = ps.farm_id
      LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
      LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
      --
      JOIN pucs ON pucs.id = ps.puc_id
      --
      JOIN orchards ON orchards.id = ps.orchard_id
      --
      JOIN cultivars ON cultivars.id = ps.cultivar_id
      --
      JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
      LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
      --
      LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
      --
      LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
      --
      JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
      --
      LEFT JOIN customer_varieties ON customer_varieties.id = ps.customer_variety_id
      LEFT JOIN marketing_varieties customer_marketing_varieties ON customer_marketing_varieties.id = customer_varieties.variety_as_customer_variety_id
      --
      JOIN marks ON marks.id = ps.mark_id
      --
      JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
      --
      JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
      --
      JOIN grades ON grades.id = ps.grade_id
      --
      LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
      --
      LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
      --
      LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
      --
      JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
      --
      JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
      --
      LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
      --
      LEFT JOIN pm_subtypes ON pm_subtypes.id = ps.pm_subtype_id
      --
      LEFT JOIN pm_types ON pm_types.id = ps.pm_type_id
      --
      JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
      --
      LEFT JOIN pallet_verification_failure_reasons ON pallet_verification_failure_reasons.id = ps.pallet_verification_failure_reason_id
      --
      LEFT JOIN personnel_identifiers ON  personnel_identifiers.id = ps.personnel_identifier_id
      --
      LEFT JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
      WHERE
      ps.pallet_id IS NOT NULL
    ;
    ALTER TABLE public.vw_pallet_sequences OWNER TO postgres;

    SQL

    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences_aggregated AS
        SELECT
            pallet_id,
            pallet_number,
            array_agg(distinct pallet_sequence_id) pallet_sequence_ids,
            string_agg(distinct sequence_status::text, ', ') sequence_statuses,
            string_agg(distinct pallet_sequence_number::text, ', ') pallet_sequence_numbers,
            string_agg(distinct packed_at::text, ', ') packed_at,
            string_agg(distinct packed_date::text, ', ') packed_dates,
            string_agg(distinct packed_week::text, ', ') packed_weeks,
            array_agg(distinct production_run_id) production_run_ids,
            array_agg(distinct season_id) season_ids,
            string_agg(distinct season_code::text, ', ') season_codes,
            array_agg(distinct farm_id) farm_ids,
            string_agg(distinct farm_code::text, ', ') farm_codes,
            string_agg(distinct farm_group_code::text, ', ') farm_group_codes,
            string_agg(distinct production_region_code::text, ', ') production_region_codes,
            array_agg(distinct puc_id) puc_ids,
            string_agg(distinct puc_code::text, ', ') puc_codes,
            array_agg(distinct orchard_id) orchard_ids,
            string_agg(distinct orchard_code::text, ', ') orchard_codes,
            string_agg(distinct commodity_code::text, ', ') commodity_codes,
            array_agg(distinct cultivar_group_id) cultivar_group_ids,
            string_agg(distinct cultivar_group_code::text, ', ') cultivar_group_codes,
            array_agg(distinct cultivar_id) cultivar_ids,
            string_agg(distinct cultivar_name::text, ', ') cultivar_names,
            string_agg(distinct cultivar_code::text, ', ') cultivar_codes,
            array_agg(distinct resource_allocation_id) resource_allocation_ids,
            array_agg(distinct packhouse_resource_id) packhouse_resource_ids,
            string_agg(distinct packhouse_code::text, ', ') packhouse_codes,
            array_agg(distinct production_line_id) production_line_ids,
            string_agg(distinct line_code::text, ', ') line_codes,
            array_agg(distinct marketing_variety_id) marketing_variety_ids,
            string_agg(distinct marketing_variety_code::text, ', ') marketing_variety_codes,
            array_agg(distinct customer_variety_id) customer_variety_ids,
            array_agg(distinct variety_as_customer_variety_id) variety_as_customer_variety_ids,
            string_agg(distinct customer_marketing_variety_code::text, ', ') customer_marketing_variety_codes,
            array_agg(distinct std_fruit_size_count_id) std_fruit_size_count_ids,
            string_agg(distinct standard_size::text, ', ') standard_sizes,
            string_agg(distinct count_group::text, ', ') count_groups,
            string_agg(distinct standard_count::text, ', ') standard_counts,
            array_agg(distinct basic_pack_code_id) basic_pack_code_ids,
            string_agg(distinct basic_pack_code::text, ', ') basic_pack_codes,
            array_agg(distinct standard_pack_code_id) standard_pack_code_ids,
            string_agg(distinct standard_pack_code::text, ', ') standard_pack_codes,
            array_agg(distinct fruit_actual_counts_for_pack_id) fruit_actual_counts_for_pack_ids,
            string_agg(distinct actual_count::text, ', ') actual_counts,
            string_agg(distinct edi_size_count::text, ', ') edi_size_counts,
            array_agg(distinct fruit_size_reference_id) fruit_size_reference_ids,
            string_agg(distinct size_ref::text, ', ') size_refs,
            array_agg(distinct marketing_org_party_role_id) marketing_org_party_role_ids,
            string_agg(distinct marketing_org::text, ', ') marketing_orgs,
            array_agg(distinct packed_tm_group_id) packed_tm_group_ids,
            string_agg(distinct packed_tm_group::text, ', ') packed_tm_groups,
            array_agg(distinct mark_id) mark_ids,
            string_agg(distinct mark::text, ', ') marks,
            array_agg(distinct inventory_code_id) inventory_code_ids,
            string_agg(distinct inventory_code::text, ', ') inventory_codes,
            array_agg(distinct pallet_format_id) pallet_format_ids,
            string_agg(distinct pallet_format::text, ', ') pallet_formats,
            array_agg(distinct cartons_per_pallet_id) cartons_per_pallet_ids,
            string_agg(distinct cartons_per_pallet::text, ', ') cartons_per_pallets,
            array_agg(distinct pm_bom_id) pm_bom_ids,
            string_agg(distinct bom_code::text, ', ') bom_codes,
            string_agg(distinct extended_columns::text, ', ') extended_columns,
            string_agg(distinct client_size_reference::text, ', ') client_size_references,
            string_agg(distinct client_product_code::text, ', ') client_product_codes,
            --
            array_agg(distinct treatment_id) treatment_ids,
            string_agg(distinct treatment_code::text, ', ') treatment_codes,
            --
            string_agg(distinct marketing_order_number::text, ', ') marketing_order_numbers,
            array_agg(distinct pm_type_id) pm_type_ids,
            string_agg(distinct pm_type_code::text, ', ') pm_type_codes,
            array_agg(distinct pm_subtype_id) pm_subtype_ids,
            string_agg(distinct subtype_code::text, ', ') subtype_codes,
            string_agg(distinct sequence_carton_quantity::text, ', ') sequence_carton_quantity,
            string_agg(distinct scanned_carton::text, ', ') scanned_cartons,
            string_agg(distinct seq_scrapped_at::text, ', ') seq_scrapped_at,
            string_agg(distinct seq_exit_ref::text, ', ') seq_exit_refs,
            string_agg(distinct verification_result::text, ', ') verification_results,
            array_agg(distinct pallet_verification_failure_reason_id) pallet_verification_failure_reason_ids,
            string_agg(distinct verification_failure_reason::text, ', ') verification_failure_reasons,
            bool_and(verified) verified,
            string_agg(distinct verified_by::text, ', ') verified_by,
            string_agg(distinct verified_at::text, ', ') verified_at,
            bool_and(verification_passed) verifications_passed,
            string_agg(distinct pick_ref::text, ', ') pick_refs,
            array_agg(distinct grade_id) grade_ids,
            string_agg(distinct grade_code::text, ', ') grade_codes,
            array_agg(distinct scrapped_from_pallet_id) scrapped_from_pallet_ids,
            bool_and(removed_from_pallet) removed_from_pallets,
            array_agg(distinct removed_from_pallet_id) removed_from_pallet_ids,
            string_agg(distinct removed_from_pallet_at::text, ', ') removed_from_pallet_at,
            string_agg(distinct sell_by_code::text, ', ') sell_by_codes,
            string_agg(distinct product_chars::text, ', ') product_chars,
            bool_and(depot_pallet) depot_pallets,
            array_agg(distinct personnel_identifier_id) personnel_identifier_ids,
            string_agg(distinct hardware_type::text, ', ') hardware_types,
            string_agg(distinct identifier::text, ', ') identifiers,
            array_agg(distinct contract_worker_id) contract_worker_ids,
            bool_and(sequence_repacked) sequence_repacked,
            string_agg(distinct sequence_repacked_at::text, ', ') sequence_repacked_at,
            array_agg(distinct repacked_from_pallet_id)  repacked_from_pallet_ids,
            --
            bool_and(failed_otmc) failed_otmc,
            array_agg(distinct failed_otmc_result_id) failed_otmc_result_ids,
            string_agg(distinct failed_otmc_result::text, ', ') failed_otmc_results,
            string_agg(distinct phyto_data::text, ', ') phyto_data,
            --
            bool_and(active) active,
            string_agg(distinct created_by::text, ', ') created_by,
            string_agg(distinct created_at::text, ', ') created_at,
            string_agg(distinct updated_at::text, ', ') updated_at
        FROM vw_pallet_sequences,
             UNNEST(CASE WHEN failed_otmc_result_ids <> '{}' THEN failed_otmc_result_ids ELSE '{null}' END) AS failed_otmc_result_id,
             UNNEST(CASE WHEN failed_otmc_results <> '{}' THEN failed_otmc_results ELSE '{null}' END) AS failed_otmc_result,
             UNNEST(CASE WHEN treatment_ids <> '{}' THEN treatment_ids ELSE '{null}' END) AS treatment_id,
             UNNEST(CASE WHEN treatment_codes <> '{}' THEN treatment_codes ELSE '{null}' END) AS treatment_code
        GROUP BY
            pallet_id,
            pallet_number;

      ALTER TABLE public.vw_pallet_sequences_aggregated OWNER TO postgres;
    SQL
  end
end
