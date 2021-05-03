# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
      DROP VIEW public.vw_pallets;
      DROP VIEW public.vw_loads;
    SQL
    # vw_pallets
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallets AS
       SELECT pallets.id,
          pallets.id AS pallet_id,
          fn_current_status('pallets'::text, pallets.id) AS status,
          pallets.pallet_number,
          fn_pallet_verification_failed(pallets.id) AS pallet_verification_failed,
          pallets.in_stock,
          pallets.stock_created_at,
          pallets.exit_ref AS exit_reference,
          pallets.location_id,
          locations.location_long_code AS location,
          pallets.pallet_format_id,
          pallet_bases.pallet_base_code AS pallet_base,
          pallet_stack_types.stack_type_code AS stack_type,
          pallets.carton_quantity,
          pallets.has_individual_cartons AS individual_cartons,
          pallets.build_status,
          pallets.phc,
          pallets.intake_created_at,
          pallets.first_cold_storage_at,
          pallets.first_cold_storage_at::date AS first_cold_storage_date,
          pallets.plt_packhouse_resource_id,
          plt_packhouses.plant_resource_code AS packhouse,
          pallets.plt_line_resource_id,
          plt_lines.plant_resource_code AS line,
          pallets.nett_weight,
          pallets.gross_weight,
          pallets.gross_weight_measured_at,
          palletizing_bays.plant_resource_code AS palletizing_bay,
          pallets.palletized,
          pallets.partially_palletized,
          pallets.palletized_at,
          pallets.palletized_at::date AS palletized_date,
          pallets.verified,
          pallets.verified_at,
          pallets.verified_at::date AS verified_date,
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
          floor(fn_calc_age_days(pallets.id, pallets.verified_at, pallets.palletized_at)) AS palletized_to_verified_age,
          floor(fn_calc_age_days(pallets.id, pallets.govt_first_inspection_at, pallets.verified_at)) AS verified_to_inspected_age,
          floor(fn_calc_age_days(pallets.id, pallets.stock_created_at, pallets.govt_first_inspection_at)) AS inspected_to_in_stock_age,
          pallets.first_cold_storage_at IS NOT NULL AS cooled,
          pallets.temp_tail,
          pallets.depot_pallet,
          pallets.fruit_sticker_pm_product_id,
          pm_products.product_code AS fruit_sticker,
          pallets.fruit_sticker_pm_product_2_id,
          pm_products_2.product_code AS fruit_sticker_2,
          pallets.load_id,
          COALESCE(pallets.load_id, 0) AS zero_load_id,
          pallets.allocated,
          pallets.allocated_at,
          pallets.shipped,
          pallets.shipped_at,
          pallets.shipped_at::date AS shipped_date,
          pallets.last_govt_inspection_pallet_id,
          govt_inspection_pallets.govt_inspection_sheet_id,
          COALESCE(govt_inspection_sheets.inspection_point, pallets.edi_in_inspection_point) AS inspection_point,
          inspected_dest_country.country_name AS inspected_dest_country,
          pallets.inspected,
          pallets.govt_first_inspection_at,
          pallets.govt_first_inspection_at::date AS govt_first_inspection_date,
          pallets.reinspected,
          pallets.govt_reinspection_at,
          pallets.govt_reinspection_at::date AS govt_reinspection_date,
          pallets.govt_inspection_passed,
          pallets.edi_in_transaction_id,
          edi_in_transactions.file_name AS edi_in_file,
          pallets.edi_in_consignment_note_number,
          pallets.edi_in_inspection_point,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at)::date AS inspection_date,
          COALESCE(pallets.edi_in_consignment_note_number,
              CASE
                  WHEN pallets.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number || ''::text
                  ELSE govt_inspection_sheets.consignment_note_number || 'F'::text
              END) AS addendum_manifest,
          govt_inspection_sheets.consignment_note_number,
          pallets.repacked,
          pallets.repacked_at,
          pallets.repacked_at::date AS repacked_date,
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
           LEFT JOIN plant_resources palletizing_bays ON palletizing_bays.id = pallets.palletizing_bay_resource_id
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
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi, commodities.use_size_ref_for_edi, fruit_size_references.edi_out_code, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack) AS edi_size_count,
          ps.fruit_size_reference_id,
          fruit_size_references.size_reference AS size_reference,
          ps.packed_tm_group_id,
          target_market_groups.target_market_group_name AS packed_tm_group,
          ps.mark_id,
          marks.mark_code AS mark,
          ps.pm_mark_id,
          pm_marks.packaging_marks,
          ps.inventory_code_id,
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
          ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS standard_cartons
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
        WHERE ps.pallet_id IS NOT NULL;

      ALTER TABLE public.vw_pallet_sequences
          OWNER TO postgres;
    SQL
    # vw_pallet_sequences_aggregated
    # ----------------------------------------------
    run <<~SQL
      create or replace function public.array_merge(arr1 anyarray, arr2 anyarray)
          returns anyarray language sql immutable
      as $$
          SELECT array_agg(DISTINCT elem ORDER BY elem)
          FROM (
              select unnest(arr1) elem 
              union
              select unnest(arr2)
          ) s
      $$;
      
      create aggregate array_merge_agg(anyarray) (
          sfunc = array_merge,
          stype = anyarray
      );
    SQL
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
          array_remove(array_agg(DISTINCT vw_pallet_sequences.standard_cartons::text),NULL) AS standard_cartons
      FROM vw_pallet_sequences
      GROUP BY vw_pallet_sequences.pallet_id, vw_pallet_sequences.pallet_number;

      ALTER TABLE public.vw_pallet_sequences_aggregated
          OWNER TO postgres;
    SQL
    # vw_loads
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_loads AS
        SELECT
            loads.id,
            loads.id AS load_id,
            'DN'::text || loads.id::text AS dispatch_note,
            fn_current_status ('loads', loads.id) AS status,
            --
            loads.rmt_load,
            loads.customer_party_role_id,
            fn_party_role_name (loads.customer_party_role_id) AS customer,
            loads.consignee_party_role_id,
            fn_party_role_name (loads.consignee_party_role_id) AS consignee,
            loads.billing_client_party_role_id,
            fn_party_role_name (loads.billing_client_party_role_id) AS billing_client,
            loads.exporter_party_role_id,
            fn_party_role_name (loads.exporter_party_role_id) AS exporter,
            loads.final_receiver_party_role_id,
            fn_party_role_name (loads.final_receiver_party_role_id) AS final_receiver,
            load_voyages.shipper_party_role_id,
            fn_party_role_name (load_voyages.shipper_party_role_id) AS shipper,
            --
            loads.final_destination_id,
            destination_cities.city_name AS final_destination,
            destination_countries.country_name AS country,
            destination_regions.destination_region_name AS region,
            --
            loads.depot_id,
            depots.depot_code AS depot,
            --
            loads.pol_voyage_port_id,
            pol_ports.port_code AS pol,
            pol_voyage_ports.etd,
            pol_voyage_ports.atd,
            COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
            --
            loads.pod_voyage_port_id,
            pod_ports.port_code AS pod,
            pod_voyage_ports.eta,
            pod_voyage_ports.ata,
            COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
            --
            loads.order_number AS internal_order_number,
            loads.edi_file_name,
            loads.customer_order_number,
            loads.customer_reference,
            loads.exporter_certificate_code,
            --
            loads.allocated,
            loads.allocated_at,
            --
            loads.shipped_at,
            loads.shipped,
            --
            loads.transfer_load,
            --
            vessels.vessel_code AS vessel,
            voyages.voyage_code AS voyage,
            voyages.voyage_number,
            load_vehicles.vehicle_number,
            load_containers.container_code AS container,
            load_containers.internal_container_code AS internal_container,
            cargo_temperatures.temperature_code AS temp_code,
            load_voyages.booking_reference,
            loads.active,
            loads.created_at,
            loads.updated_at
        FROM loads
        --
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
        LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        --
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        --
        LEFT JOIN depots ON depots.id = loads.depot_id
        --
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
        LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
        --
        LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
        --
        LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        ;      
        ALTER TABLE public.vw_loads OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_pallet_sequences_aggregated;
      DROP VIEW public.vw_pallet_sequences;
      DROP VIEW public.vw_pallets;
      DROP VIEW public.vw_loads;
    SQL
    # vw_pallets
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallets AS
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
          CASE 
            WHEN (pallets.first_cold_storage_at IS NULL) THEN false
            ELSE true 
          END AS cooled,
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
                  WHEN pallets.govt_inspection_passed THEN govt_inspection_sheets.consignment_note_number || ''::text
                  ELSE govt_inspection_sheets.consignment_note_number || 'F'::text
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
          target_markets.target_market_name AS target_market,
          ps.carton_quantity::numeric / standard_product_weights.ratio_to_standard_carton AS std_ctns
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
           LEFT JOIN standard_product_weights ON standard_product_weights.standard_pack_id = standard_pack_codes.id AND standard_product_weights.commodity_id = commodities.id
        WHERE ps.pallet_id IS NOT NULL;

      ALTER TABLE public.vw_pallet_sequences
          OWNER TO postgres;
    SQL
    # vw_pallet_sequences_aggregated
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_pallet_sequences_aggregated
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
          string_agg(DISTINCT vw_pallet_sequences.target_market, ', '::text) AS target_market,
          array_agg(DISTINCT vw_pallet_sequences.std_ctns) AS std_ctns
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
    run <<~SQL
      DROP AGGREGATE public.array_merge_agg(anyarray);
      DROP FUNCTION public.array_merge;
    SQL
    # vw_loads
    # ----------------------------------------------
    run <<~SQL
      CREATE VIEW public.vw_loads AS
        SELECT
            loads.id AS load_id,
            fn_current_status ('loads', loads.id) AS load_status,
            --
            loads.rmt_load,
            loads.customer_party_role_id,
            fn_party_role_name (loads.customer_party_role_id) AS customer,
            loads.consignee_party_role_id,
            fn_party_role_name (loads.consignee_party_role_id) AS consignee,
            loads.billing_client_party_role_id,
            fn_party_role_name (loads.billing_client_party_role_id) AS billing_client,
            loads.exporter_party_role_id,
            fn_party_role_name (loads.exporter_party_role_id) AS exporter,
            loads.final_receiver_party_role_id,
            fn_party_role_name (loads.final_receiver_party_role_id) AS final_receiver,
            load_voyages.shipper_party_role_id,
            fn_party_role_name (load_voyages.shipper_party_role_id) AS shipper,
            --
            loads.final_destination_id,
            destination_cities.city_name AS final_destination,
            destination_countries.country_name AS country,
            destination_regions.destination_region_name AS region,
            --
            loads.depot_id,
            depots.depot_code,
            --
            loads.pol_voyage_port_id,
            pol_ports.port_code AS pol,
            pol_voyage_ports.etd,
            pol_voyage_ports.atd,
            COALESCE(pol_voyage_ports.atd, pol_voyage_ports.etd) AS departure_date,
            --
            loads.pod_voyage_port_id,
            pod_ports.port_code AS pod,
            pod_voyage_ports.eta,
            pod_voyage_ports.ata,
            COALESCE(pod_voyage_ports.ata, pod_voyage_ports.eta) AS arrival_date,
            --
            loads.order_number AS internal_order_number,
            loads.edi_file_name,
            loads.customer_order_number,
            loads.customer_reference,
            loads.exporter_certificate_code,
            --
            loads.allocated,
            loads.allocated_at,
            --
            loads.shipped_at,
            loads.shipped,
            --
            loads.transfer_load,
            --
            vessels.vessel_code AS vessel,
            voyages.voyage_code AS voyage,
            voyages.voyage_number,
            load_vehicles.vehicle_number,
            load_containers.container_code AS container,
            load_containers.internal_container_code AS internal_container,
            cargo_temperatures.temperature_code AS temp_code,
            load_voyages.booking_reference,
            loads.active,
            loads.created_at,
            loads.updated_at
        FROM loads
        --
        LEFT JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
        LEFT JOIN ports pol_ports ON pol_ports.id = pol_voyage_ports.port_id
        LEFT JOIN voyages ON voyages.id = pol_voyage_ports.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        --
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        --
        LEFT JOIN depots ON depots.id = loads.depot_id
        --
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        LEFT JOIN load_vehicles ON load_vehicles.load_id = loads.id
        LEFT JOIN load_voyages ON loads.id = load_voyages.load_id
        --
        LEFT JOIN destination_cities ON destination_cities.id = loads.final_destination_id
        LEFT JOIN destination_countries ON destination_countries.id = destination_cities.destination_country_id
        LEFT JOIN destination_regions ON destination_regions.id = destination_countries.destination_region_id
        --
        LEFT JOIN cargo_temperatures ON cargo_temperatures.id = load_containers.cargo_temperature_id
        ;      
        ALTER TABLE public.vw_loads OWNER TO postgres;
    SQL
  end
end
