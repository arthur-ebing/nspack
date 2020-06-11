Sequel.migration do
  up do
    run <<~SQL
     DROP VIEW public.vw_packout_details;
      CREATE OR REPLACE VIEW public.vw_packout_details AS
       SELECT farms.farm_code,
          ( SELECT string_agg(sub.orchard_code::text, '; '::text) AS string_agg
                 FROM ( SELECT DISTINCT orchards.orchard_code
                         FROM rmt_bins
                           JOIN orchards ON orchards.id = rmt_bins.orchard_id
                        WHERE rmt_bins.production_run_tipped_id = production_runs.id) sub) AS orchards,
          date_trunc('day'::text, pallet_sequences.created_at) AS pack_date,
          date_part('week'::text, pallet_sequences.created_at) AS pack_week,
          ( SELECT string_agg(sub.rmt_delivery_id::text, '; '::text) AS string_agg
                 FROM ( SELECT DISTINCT rmt_bins.rmt_delivery_id
                         FROM rmt_bins
                        WHERE rmt_bins.production_run_tipped_id = pallet_sequences.production_run_id
                        ORDER BY rmt_bins.rmt_delivery_id) sub) AS deliveries,
          production_run_stats.bins_tipped AS no_of_bins,
          production_run_stats.bins_tipped_weight::numeric(12,2) AS total_bin_weight,
          production_run_stats.cartons_verified_weight::numeric(12,2) AS total_packed_weight,
          production_run_stats.pallet_weight::numeric(12,2) AS total_pallet_weight,
              CASE production_run_stats.bins_tipped_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (production_run_stats.cartons_verified_weight / production_run_stats.bins_tipped_weight * 100::numeric)::numeric(7,2)
              END AS run_carton_percentage,
              CASE production_run_stats.bins_tipped_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (production_run_stats.pallet_weight / production_run_stats.bins_tipped_weight * 100::numeric)::numeric(7,2)
              END AS run_pallet_percentage,
          COALESCE(cultivars.cultivar_name, cultivar_groups.cultivar_group_code) AS cultivar,
          marketing_varieties.marketing_variety_code,
          pallet_sequences.production_run_id,
          fn_production_run_code(pallet_sequences.production_run_id) AS production_run_code,
          grades.grade_code,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          basic_pack_codes.basic_pack_code AS basic_pack,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          inventory_codes.inventory_code,
          pallet_sequences.nett_weight::numeric(12,2) AS nett_weight,
          pallet_sequences.carton_quantity,
              CASE production_run_stats.cartons_verified_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (pallet_sequences.nett_weight / production_run_stats.cartons_verified_weight * 100::numeric)::numeric(7,2)
              END AS percentage,
          standard_product_weights.nett_weight * pallet_sequences.carton_quantity::numeric AS derived_nett_weight
         FROM pallet_sequences
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = (( SELECT rmt_bins.farm_id
                 FROM rmt_bins
                WHERE rmt_bins.production_run_tipped_id = production_runs.id
               LIMIT 1))
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           LEFT JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           LEFT JOIN standard_product_weights ON commodities.id = standard_product_weights.commodity_id AND standard_product_weights.standard_pack_id = standard_pack_codes.id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN production_run_stats ON production_run_stats.production_run_id = pallet_sequences.production_run_id
        WHERE pallet_sequences.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_packout_details
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
     DROP VIEW public.vw_packout_details;
      CREATE OR REPLACE VIEW public.vw_packout_details AS
       SELECT farms.farm_code,
          ( SELECT string_agg(sub.orchard_code::text, '; '::text) AS string_agg
                 FROM ( SELECT DISTINCT orchards.orchard_code
                         FROM rmt_bins
                           JOIN orchards ON orchards.id = rmt_bins.orchard_id
                        WHERE rmt_bins.production_run_tipped_id = production_runs.id) sub) AS orchards,
          date_trunc('day'::text, pallet_sequences.created_at) AS pack_date,
          date_part('week'::text, pallet_sequences.created_at) AS pack_week,
          ( SELECT string_agg(sub.rmt_delivery_id::text, '; '::text) AS string_agg
                 FROM ( SELECT DISTINCT rmt_bins.rmt_delivery_id
                         FROM rmt_bins
                        WHERE rmt_bins.production_run_tipped_id = pallet_sequences.production_run_id) sub) AS deliveries,
          production_run_stats.bins_tipped AS no_of_bins,
          production_run_stats.bins_tipped_weight::numeric(12,2) AS total_bin_weight,
          production_run_stats.cartons_verified_weight::numeric(12,2) AS total_packed_weight,
          production_run_stats.pallet_weight::numeric(12,2) AS total_pallet_weight,
              CASE production_run_stats.bins_tipped_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (production_run_stats.cartons_verified_weight / production_run_stats.bins_tipped_weight * 100::numeric)::numeric(7,2)
              END AS run_carton_percentage,
              CASE production_run_stats.bins_tipped_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (production_run_stats.pallet_weight / production_run_stats.bins_tipped_weight * 100::numeric)::numeric(7,2)
              END AS run_pallet_percentage,
          COALESCE(cultivars.cultivar_name, cultivar_groups.cultivar_group_code) AS cultivar,
          marketing_varieties.marketing_variety_code,
          pallet_sequences.production_run_id,
          fn_production_run_code(pallet_sequences.production_run_id) AS production_run_code,
          grades.grade_code,
          packhouses.plant_resource_code AS packhouse,
          lines.plant_resource_code AS line,
          basic_pack_codes.basic_pack_code AS basic_pack,
          std_fruit_size_counts.size_count_value AS std_size,
          fruit_size_references.size_reference AS size_ref,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          inventory_codes.inventory_code,
          pallet_sequences.nett_weight::numeric(12,2) AS nett_weight,
          pallet_sequences.carton_quantity,
              CASE production_run_stats.cartons_verified_weight
                  WHEN 0 THEN 0.0::numeric(7,2)
                  ELSE (pallet_sequences.nett_weight / production_run_stats.cartons_verified_weight * 100::numeric)::numeric(7,2)
              END AS percentage,
          standard_product_weights.nett_weight * pallet_sequences.carton_quantity::numeric AS derived_nett_weight
         FROM pallet_sequences
           JOIN production_runs ON production_runs.id = pallet_sequences.production_run_id
           JOIN plant_resources packhouses ON packhouses.id = pallet_sequences.packhouse_resource_id
           JOIN plant_resources lines ON lines.id = pallet_sequences.production_line_id
           JOIN farms ON farms.id = (( SELECT rmt_bins.farm_id
                 FROM rmt_bins
                WHERE rmt_bins.production_run_tipped_id = production_runs.id
               LIMIT 1))
           JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
           LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
           LEFT JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
           LEFT JOIN standard_product_weights ON commodities.id = standard_product_weights.commodity_id AND standard_product_weights.standard_pack_id = standard_pack_codes.id
           JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
           JOIN grades ON grades.id = pallet_sequences.grade_id
           LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
           LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
           LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
           JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
           JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
           JOIN production_run_stats ON production_run_stats.production_run_id = pallet_sequences.production_run_id
        WHERE pallet_sequences.pallet_id IS NOT NULL;
      
      ALTER TABLE public.vw_packout_details
          OWNER TO postgres;
    SQL
  end
end
