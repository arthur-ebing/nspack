Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_bins;
    SQL
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_bins
      AS SELECT rmt_bins.id,
          rmt_bins.rmt_delivery_id,
          rmt_bins.season_id,
              CASE
                  WHEN rmt_bins.qty_bins = 1 THEN true
                  ELSE false
              END AS discrete_bin,
          rmt_bins.cultivar_id,
          rmt_bins.orchard_id,
          rmt_bins.farm_id,
          rmt_bins.rmt_class_id,
          rmt_bins.rmt_container_type_id,
          rmt_bins.rmt_container_material_type_id,
          rmt_bins.cultivar_group_id,
          rmt_bins.puc_id,
          rmt_bins.exit_ref,
          rmt_bins.qty_bins,
          rmt_bins.bin_asset_number,
          rmt_bins.tipped_asset_number,
          rmt_bins.rmt_inner_container_type_id,
          rmt_bins.rmt_inner_container_material_id,
          rmt_bins.qty_inner_bins,
          rmt_bins.production_run_rebin_id,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.active,
          rmt_bins.bin_tipped,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.bin_received_date_time,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          rmt_bins.bin_tipped_date_time,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.exit_ref_date_time,
          rmt_bins.rebin_created_at,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          rmt_classes.rmt_class_code,
          rmt_container_material_types.container_material_type_code,
          rmt_container_types.container_type_code,
          rmt_deliveries.truck_registration_number AS rmt_delivery_truck_registration_number,
          seasons.season_code,
              CASE
                  WHEN rmt_bins.bin_tipped THEN 'gray'::text
                  ELSE NULL::text
              END AS colour_rule,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status
         FROM rmt_bins
           LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
           LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
           JOIN seasons ON seasons.id = rmt_bins.season_id;
        
        ALTER TABLE public.vw_bins
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_bins;
    SQL
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_bins
      AS SELECT rmt_bins.id,
          rmt_bins.rmt_delivery_id,
          rmt_bins.season_id,
              CASE
                  WHEN rmt_bins.qty_bins = 1 THEN true
                  ELSE false
              END AS discrete_bin,
          rmt_bins.cultivar_id,
          rmt_bins.orchard_id,
          rmt_bins.farm_id,
          rmt_bins.rmt_class_id,
          rmt_bins.rmt_container_type_id,
          rmt_bins.rmt_container_material_type_id,
          rmt_bins.cultivar_group_id,
          rmt_bins.puc_id,
          rmt_bins.exit_ref,
          rmt_bins.qty_bins,
          rmt_bins.bin_asset_number,
          rmt_bins.tipped_asset_number,
          rmt_bins.rmt_inner_container_type_id,
          rmt_bins.rmt_inner_container_material_id,
          rmt_bins.qty_inner_bins,
          rmt_bins.production_run_rebin_id,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.active,
          rmt_bins.bin_tipped,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_bins.bin_received_date_time,
          rmt_bins.bin_tipped_date_time,
          rmt_bins.exit_ref_date_time,
          rmt_bins.rebin_created_at,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          cultivar_groups.cultivar_group_code,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          rmt_classes.rmt_class_code,
          rmt_container_material_types.container_material_type_code,
          rmt_container_types.container_type_code,
          rmt_deliveries.truck_registration_number AS rmt_delivery_truck_registration_number,
          seasons.season_code,
              CASE
                  WHEN rmt_bins.bin_tipped THEN 'gray'::text
                  ELSE NULL::text
              END AS colour_rule,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status
         FROM rmt_bins
           LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
           LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
           JOIN seasons ON seasons.id = rmt_bins.season_id;
        
        ALTER TABLE public.vw_bins
        OWNER TO postgres;
    SQL
  end
end
