# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
    SQL
    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences
       AS
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
          ps.repacked_at AS repacked_at,
          ps.repacked_from_pallet_id,
          (SELECT pallet_number FROM pallets WHERE id = ps.repacked_from_pallet_id) AS repacked_from_pallet_number,
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
          target_markets.target_market_name AS target_market,
          ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS standard_cartons,
          ps.rmt_class_id,
          rmt_classes.rmt_class_code AS rmt_class
        
         FROM pallet_sequences ps
           JOIN seasons ON seasons.id = ps.season_id
           JOIN farms ON farms.id = ps.farm_id
           LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
           LEFT JOIN production_regions ON production_regions.id = farms.pdn_region_id
           JOIN pucs ON pucs.id = ps.puc_id
           JOIN orchards ON orchards.id = ps.orchard_id
           LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
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
        WHERE ps.pallet_id IS NOT NULL;

      ALTER TABLE public.vw_pallet_sequences
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
  end
  down do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
    SQL
    # vw_pallet_sequences
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences
       AS
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
          ps.repacked_at AS repacked_at,
          ps.repacked_from_pallet_id,
          (SELECT pallet_number FROM pallets WHERE id = ps.repacked_from_pallet_id) AS repacked_from_pallet_number,
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
          target_markets.target_market_name AS target_market,
          ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS standard_cartons,
          ps.rmt_class_id,
          rmt_classes.rmt_class_code AS rmt_class
        
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
        WHERE ps.pallet_id IS NOT NULL;

      ALTER TABLE public.vw_pallet_sequences
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
  end
end
