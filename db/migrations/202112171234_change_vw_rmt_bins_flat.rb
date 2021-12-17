Sequel.migration do
  up do
    # vw_rmt_bins_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_rmt_bins_flat;

      CREATE VIEW public.vw_rmt_bins_flat AS
       SELECT rmt_bins.id,
          COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number) AS asset_number,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status,
          rmt_bins.presort_staging_run_child_id,
          rmt_bins.tipped_in_presort_at,
          rmt_bins.staged_for_presorting_at,
          rmt_bins.presort_tip_lot_number,
          rmt_bins.mixed,
          rmt_bins.presorted,
          rmt_bins.main_presort_run_lot_number,
          rmt_bins.staged_for_presorting,
          rmt_bins.qty_bins,
          rmt_bins.legacy_data,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_bins.qty_bins = 1 AS discrete_bin,
          rmt_bins.qty_inner_bins,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.weighed_manually,
          rmt_bins.active,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_bins.location_id,
          locations.location_long_code,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          plant_resources.plant_resource_code AS packhouse,
          rmt_bins.season_id,
          seasons.season_code,
          rmt_bins.farm_id,
          farm_groups.farm_group_code,
          farms.farm_code,
          rmt_bins.puc_id,
          pucs.puc_code,
          rmt_bins.orchard_id,
          orchards.orchard_code,
          rmt_bins.cultivar_group_id,
          cultivar_groups.cultivar_group_code,
          rmt_bins.cultivar_id,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          cultivars.description AS cultivar_description,
          commodities.code AS commodity_code,
          rmt_bins.rmt_class_id,
          rmt_classes.rmt_class_code,
          rmt_bins.rmt_material_owner_party_role_id,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          rmt_bins.rmt_container_type_id,
          rmt_container_types.container_type_code,
          rmt_bins.rmt_container_material_type_id,
          rmt_container_material_types.container_material_type_code,
          rmt_bins.rmt_inner_container_type_id,
          rmt_inner_container_types.container_type_code AS inner_container_type_code,
          rmt_bins.rmt_inner_container_material_id,
          rmt_inner_container_material_types.container_material_type_code AS inner_container_material_type_code,
          rmt_bins.scrapped_rmt_delivery_id,
          rmt_bins.rmt_delivery_id,
          rmt_delivery_destinations.delivery_destination_code,
          rmt_deliveries.date_picked AS picked_at,
          rmt_deliveries.truck_registration_number AS delivery_truck_registration_number,
          rmt_bins.exit_ref,
          rmt_bins.exit_ref IS NULL AS null_exit_ref,
          rmt_bins.exit_ref_date_time AS exit_ref_at,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.bin_asset_number,
          rmt_bins.bin_received_date_time AS bin_received_at,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.tipped_asset_number,
          rmt_bins.bin_tipped,
          rmt_bins.tipped_manually,
          rmt_bins.bin_tipped_date_time AS bin_tipped_at,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          date_part('week'::text, rmt_bins.bin_tipped_date_time) AS bin_tipped_week,
          rmt_bins.shipped_asset_number,
          bin_loads.shipped IS TRUE AS shipped,
          bin_loads.shipped_at,
          bin_load_products.bin_load_id,
          rmt_bins.bin_load_product_id,
          rmt_bins.scrapped_bin_asset_number,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          rmt_bins.scrap_remarks,
          rmt_bins.unscrapped_at,
          rmt_bins.production_run_rebin_id,
          rmt_bins.rebin_created_at,
          rmt_bins.avg_gross_weight,
          farm_sections.farm_section_name,
          fn_party_role_name(farm_sections.farm_manager_party_role_id) AS farm_manager,
          floor(ABS(date_part('epoch', COALESCE(rmt_bins.bin_received_date_time::timestamp, rmt_bins.created_at::timestamp) - COALESCE(rmt_bins.exit_ref_date_time::timestamp, current_timestamp)) / 86400)) AS age,
          lines.plant_resource_code AS tip_line,
          rmt_bins.coldroom_events,
          concat_ws(' ',
                    location_coldroom_events.event_name,
                    to_char (location_coldroom_events.created_at, 'YYYY-MM-DD HH24:MI:SS'),
                    cold_loc.location_long_code) AS last_coldroom_event,
          rmt_bins.rmt_classifications,
          ( SELECT array_agg(DISTINCT rmt_classifications.rmt_classification) AS array_agg
            FROM rmt_classifications
            WHERE rmt_classifications.id = ANY (rmt_bins.rmt_classifications)
            GROUP BY rmt_bins.id) AS classifications,
          rmt_bins.main_ripeness_treatment_id,
          main_ripeness_treatments.treatment_code AS main_ripeness_treatment,
          rmt_bins.main_cold_treatment_id,
          main_cold_treatments.treatment_code AS main_cold_treatment,
          rmt_bins.rmt_treatments,
          ( SELECT array_agg(DISTINCT treatments.treatment_code) AS array_agg
            FROM treatments
            WHERE treatments.id = ANY (rmt_bins.rmt_treatments)
            GROUP BY rmt_bins.id) AS treatments

         FROM rmt_bins
           LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN farm_sections ON farm_sections.id = orchards.farm_section_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
           LEFT JOIN rmt_container_material_types rmt_inner_container_material_types ON rmt_inner_container_material_types.id = rmt_bins.rmt_inner_container_material_id
           LEFT JOIN rmt_container_types rmt_inner_container_types ON rmt_inner_container_types.id = rmt_bins.rmt_inner_container_type_id
           LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
           LEFT JOIN rmt_delivery_destinations ON rmt_delivery_destinations.id = rmt_deliveries.rmt_delivery_destination_id
           LEFT JOIN locations ON locations.id = rmt_bins.location_id
           LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_tipped_id
           LEFT JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = production_runs.production_line_id
           LEFT JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
           LEFT JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
           LEFT JOIN rmt_sizes ON rmt_sizes.id=rmt_bins.rmt_size_id
           LEFT JOIN location_coldroom_events ON location_coldroom_events.id = rmt_bins.coldroom_events[array_upper(rmt_bins.coldroom_events, 1)]
           LEFT JOIN locations cold_loc ON cold_loc.id = location_coldroom_events.location_id
           LEFT JOIN treatments main_ripeness_treatments ON main_ripeness_treatments.id = rmt_bins.main_ripeness_treatment_id
           LEFT JOIN treatments main_cold_treatments ON main_cold_treatments.id = rmt_bins.main_cold_treatment_id;
    SQL
  end

  down do
    # vw_rmt_bins_flat
    # ----------------------------------------------
    run <<~SQL
      DROP VIEW public.vw_rmt_bins_flat;

      CREATE VIEW public.vw_rmt_bins_flat AS
       SELECT rmt_bins.id,
          COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number) AS asset_number,
          fn_current_status('rmt_bins'::text, rmt_bins.id) AS status,
          rmt_bins.presort_staging_run_child_id,
          rmt_bins.tipped_in_presort_at,
          rmt_bins.staged_for_presorting_at,
          rmt_bins.presort_tip_lot_number,
          rmt_bins.mixed,
          rmt_bins.presorted,
          rmt_bins.main_presort_run_lot_number,
          rmt_bins.staged_for_presorting,
          rmt_bins.qty_bins,
          rmt_bins.legacy_data,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_bins.qty_bins = 1 AS discrete_bin,
          rmt_bins.qty_inner_bins,
          rmt_bins.bin_fullness,
          rmt_bins.nett_weight,
          rmt_bins.gross_weight,
          rmt_bins.weighed_manually,
          rmt_bins.active,
          rmt_bins.created_at,
          rmt_bins.updated_at,
          rmt_bins.location_id,
          locations.location_long_code,
          rmt_bins.production_run_tipped_id,
          rmt_bins.bin_tipping_plant_resource_id,
          plant_resources.plant_resource_code AS packhouse,
          rmt_bins.season_id,
          seasons.season_code,
          rmt_bins.farm_id,
          farm_groups.farm_group_code,
          farms.farm_code,
          rmt_bins.puc_id,
          pucs.puc_code,
          rmt_bins.orchard_id,
          orchards.orchard_code,
          rmt_bins.cultivar_group_id,
          cultivar_groups.cultivar_group_code,
          rmt_bins.cultivar_id,
          cultivars.cultivar_name,
          cultivars.cultivar_code,
          cultivars.description AS cultivar_description,
          commodities.code AS commodity_code,
          rmt_bins.rmt_class_id,
          rmt_classes.rmt_class_code,
          rmt_bins.rmt_material_owner_party_role_id,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          rmt_bins.rmt_container_type_id,
          rmt_container_types.container_type_code,
          rmt_bins.rmt_container_material_type_id,
          rmt_container_material_types.container_material_type_code,
          rmt_bins.rmt_inner_container_type_id,
          rmt_inner_container_types.container_type_code AS inner_container_type_code,
          rmt_bins.rmt_inner_container_material_id,
          rmt_inner_container_material_types.container_material_type_code AS inner_container_material_type_code,
          rmt_bins.scrapped_rmt_delivery_id,
          rmt_bins.rmt_delivery_id,
          rmt_delivery_destinations.delivery_destination_code,
          rmt_deliveries.date_picked AS picked_at,
          rmt_deliveries.truck_registration_number AS delivery_truck_registration_number,
          rmt_bins.exit_ref,
          rmt_bins.exit_ref IS NULL AS null_exit_ref,
          rmt_bins.exit_ref_date_time AS exit_ref_at,
          rmt_bins.exit_ref_date_time::date AS exit_ref_date,
          rmt_bins.bin_asset_number,
          rmt_bins.bin_received_date_time AS bin_received_at,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          rmt_bins.tipped_asset_number,
          rmt_bins.bin_tipped,
          rmt_bins.tipped_manually,
          rmt_bins.bin_tipped_date_time AS bin_tipped_at,
          rmt_bins.bin_tipped_date_time::date AS bin_tipped_date,
          date_part('week'::text, rmt_bins.bin_tipped_date_time) AS bin_tipped_week,
          rmt_bins.shipped_asset_number,
          bin_loads.shipped IS TRUE AS shipped,
          bin_loads.shipped_at,
          bin_load_products.bin_load_id,
          rmt_bins.bin_load_product_id,
          rmt_bins.scrapped_bin_asset_number,
          rmt_bins.scrapped,
          rmt_bins.scrapped_at,
          rmt_bins.scrap_remarks,
          rmt_bins.unscrapped_at,
          rmt_bins.production_run_rebin_id,
          rmt_bins.rebin_created_at,
          rmt_bins.avg_gross_weight,
          farm_sections.farm_section_name,
          fn_party_role_name(farm_sections.farm_manager_party_role_id) AS farm_manager,
          floor(ABS(date_part('epoch', COALESCE(rmt_bins.bin_received_date_time::timestamp, rmt_bins.created_at::timestamp) - COALESCE(rmt_bins.exit_ref_date_time::timestamp, current_timestamp)) / 86400)) AS age,
          lines.plant_resource_code AS tip_line,
          rmt_bins.coldroom_events,
          concat_ws(' ',
                    location_coldroom_events.event_name,
                    to_char (location_coldroom_events.created_at, 'YYYY-MM-DD HH24:MI:SS'),
                    cold_loc.location_long_code) AS last_coldroom_event

         FROM rmt_bins
           LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
           LEFT JOIN farms ON farms.id = rmt_bins.farm_id
           LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
           LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
           LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
           LEFT JOIN farm_sections ON farm_sections.id = orchards.farm_section_id
           LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
           LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
           LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
           LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
           LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
           LEFT JOIN rmt_container_types ON rmt_container_types.id = rmt_bins.rmt_container_type_id
           LEFT JOIN rmt_container_material_types rmt_inner_container_material_types ON rmt_inner_container_material_types.id = rmt_bins.rmt_inner_container_material_id
           LEFT JOIN rmt_container_types rmt_inner_container_types ON rmt_inner_container_types.id = rmt_bins.rmt_inner_container_type_id
           LEFT JOIN rmt_deliveries ON rmt_deliveries.id = rmt_bins.rmt_delivery_id
           LEFT JOIN rmt_delivery_destinations ON rmt_delivery_destinations.id = rmt_deliveries.rmt_delivery_destination_id
           LEFT JOIN locations ON locations.id = rmt_bins.location_id
           LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_tipped_id
           LEFT JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
           LEFT JOIN plant_resources lines ON lines.id = production_runs.production_line_id
           LEFT JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
           LEFT JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
           LEFT JOIN rmt_sizes ON rmt_sizes.id=rmt_bins.rmt_size_id
           LEFT JOIN location_coldroom_events ON location_coldroom_events.id = rmt_bins.coldroom_events[array_upper(rmt_bins.coldroom_events, 1)]
           LEFT JOIN locations cold_loc ON cold_loc.id = location_coldroom_events.location_id;
    SQL
  end
end
