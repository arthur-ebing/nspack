# frozen_string_literal: true

module EdiApp
  class HbsOutRepo < BaseRepo
    def hbs_rmt_rows(load_id)
      query = <<~SQL
        SELECT
          'BS' || lpad(bin_loads.id::text, 6, '0') AS load_id,
          rmt_bins.nett_weight AS weight,
          rmt_classes.description AS class,
          commodities.code AS fruit_class,
          coalesce(rmt_sizes.size_code,'UNS') AS bin_size,
          COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number) AS bin_id,
          'BS' || lpad(bin_loads.id::text, 6, '0') AS exit_ref,
          COALESCE(rmt_bins.exit_ref_date_time, rmt_bins.updated_at) AS exit_date,
          customers.financial_account_code AS hw_customer_code,
          customers.financial_account_code AS trading_partner,
          'BINSALES' AS line_of_business,
          rmt_codes.rmt_code AS current_rmt_type,
          cultivars.cultivar_code AS cultivar,
          1 AS qty,
          seasons.season_year season,
          farms.farm_code AS farm_id,
          farm_groups.farm_group_code AS farm_sub_group,
          concat(rmt_codes.rmt_code::text, '_', commodities.code, '_', cultivars.cultivar_code, '_', coalesce(colour_percentages.colour_percentage,'STD')::text, '_', coalesce(rmt_classes.rmt_class_code,'OR'), '_',  coalesce(rmt_sizes.size_code,'UNS')) AS product_code
        FROM
          rmt_bins
          LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
          LEFT JOIN farms ON farms.id = rmt_bins.farm_id
          LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
          LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
          LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
          LEFT JOIN farm_sections ON farm_sections.id = orchards.farm_section_id
          LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
          LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
          LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
          LEFT JOIN rmt_sizes ON rmt_sizes.id = rmt_bins.rmt_size_id
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
          LEFT JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
          LEFT JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
          LEFT JOIN customers ON customers.customer_party_role_id = bin_loads.customer_party_role_id
          LEFT JOIN rmt_codes ON rmt_codes.id = rmt_bins.rmt_code_id
          LEFT JOIN colour_percentages ON colour_percentages.id = rmt_bins.colour_percentage_id
        WHERE bin_load_products.bin_load_id = ?
        ORDER BY COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number)
      SQL
      DB[query, load_id].all
    end

    def hbs_fg_rows(load_id)
      # TODO: This query WILL bomb
      query = <<~SQL
        SELECT
          bin_loads.id AS load_id,
          rmt_bins.nett_weight AS weight,
          rmt_classes.description AS class,
          commodities.code AS fruit_class,
          rmt_sizes.size_code AS bin_size,
          COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number) AS bin_id,
          bin_loads.id AS exit_ref,
          COALESCE(rmt_bins.exit_ref_date_time, rmt_bins.updated_at) AS exit_date,
          customers.financial_account_code AS hw_customer_code,
          customers.financial_account_code AS trading_partner,
          'BINSALES' AS line_of_business,
          rmt_bins.legacy_data ->> 'track_slms_indicator_1_code' AS current_rmt_type,
          cultivars.cultivar_code AS cultivar,
          1 AS qty,
          seasons.season_year season,
          farms.farm_code AS farm_id,
          farm_groups.farm_group_code AS farm_sub_group,
          concat(rmt_bins.legacy_data ->> 'track_slms_indicator_1_code'::text, '_', commodities.code, '_', cultivars.cultivar_code, '_', rmt_bins.legacy_data ->> 'rmtp_treatment_code'::text, '_', rmt_classes.rmt_class_code, '_', rmt_bins.legacy_data ->> 'ripe_point_code'::text, '_', rmt_sizes.size_code) AS product_code
        FROM
          rmt_bins
          LEFT JOIN seasons ON seasons.id = rmt_bins.season_id
          LEFT JOIN farms ON farms.id = rmt_bins.farm_id
          LEFT JOIN farm_groups ON farm_groups.id = farms.farm_group_id
          LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
          LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
          LEFT JOIN farm_sections ON farm_sections.id = orchards.farm_section_id
          LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
          LEFT JOIN cultivar_groups ON cultivar_groups.id = COALESCE(rmt_bins.cultivar_group_id, cultivars.cultivar_group_id)
          LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
          LEFT JOIN rmt_sizes ON rmt_sizes.id = rmt_bins.rmt_size_id
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
          LEFT JOIN bin_load_products ON bin_load_products.id = rmt_bins.bin_load_product_id
          LEFT JOIN bin_loads ON bin_loads.id = bin_load_products.bin_load_id
          LEFT JOIN customers ON customers.customer_party_role_id = loads.customer_party_role_id
        WHERE bin_load_products.bin_load_id = ?
        ORDER BY COALESCE(rmt_bins.bin_asset_number, rmt_bins.tipped_asset_number, rmt_bins.shipped_asset_number, rmt_bins.scrapped_bin_asset_number)
      SQL
      DB[query, load_id].all
    end

    def log_hbs_success(file_name, record_id)
      log_status(:loads, record_id, 'HBS SENT', user_name: 'System', comment: file_name)
    end

    def log_hbs_fail(record_id, message)
      log_status(:loads, record_id, 'HBS SEND FAILURE', user_name: 'System', comment: message)
    end
  end
end
