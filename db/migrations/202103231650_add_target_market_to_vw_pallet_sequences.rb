# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
    SQL
    run <<~SQL

      CREATE OR REPLACE VIEW public.vw_pallet_sequences
       AS
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
          fn_party_role_name(ps.target_customer_party_role_id) AS target_customer,
          target_markets.target_market_name AS target_market
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
           LEFT JOIN target_markets ON target_markets.id = ps.target_market_id

        WHERE ps.pallet_id IS NOT NULL;

      ALTER TABLE public.vw_pallet_sequences
          OWNER TO postgres;

    SQL
    run <<~SQL
            -- View: public.vw_pallet_sequences_aggregated

      -- DROP VIEW public.vw_pallet_sequences_aggregated;

      CREATE OR REPLACE VIEW public.vw_pallet_sequences_aggregated
       AS
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
          string_agg(DISTINCT vw_pallet_sequences.updated_at::text, ', '::text) AS updated_at,
          string_agg(DISTINCT vw_pallet_sequences.target_market::text, ', '::text) AS target_market
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
  end

  down do
    run <<~SQL

      CREATE OR REPLACE VIEW public.vw_pallet_sequences
       AS
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

    SQL
    run <<~SQL

      CREATE OR REPLACE VIEW public.vw_pallet_sequences_aggregated
       AS
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

  end
end
