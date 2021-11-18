Sequel.migration do
  up do
    run <<~SQL
      DROP VIEW public.vw_rebin_label;
      CREATE VIEW public.vw_rebin_label AS
        SELECT
          rmt_bins.id,
          rmt_bins.bin_asset_number,
          rmt_bins.gross_weight,
          rmt_bins.nett_weight,
          rmt_bins.production_run_rebin_id AS production_run_id,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          to_char(rmt_bins.created_at AT TIME ZONE 'Africa/Johannesburg', 'YYYY-mm-dd HH24:MI'::text) AS created_at,
          plant_resources.plant_resource_code AS line,
          rmt_sizes.size_code AS rmt_size_code,
          rmt_container_material_types.container_material_type_code,
          fn_party_role_name(rmt_bins.rmt_material_owner_party_role_id) AS container_material_owner,
          production_runs.legacy_data ->> 'track_indicator_code' AS track_indicator_code,
          production_runs.legacy_data ->> 'pc_code' AS pc_code
        FROM
          rmt_bins
          LEFT JOIN farms ON farms.id = rmt_bins.farm_id
          LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
          LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
          LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
          LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
          LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
          LEFT JOIN rmt_sizes ON rmt_sizes.id = rmt_bins.rmt_size_id
          LEFT JOIN production_runs ON production_runs.id = rmt_bins.production_run_rebin_id
          LEFT JOIN plant_resources ON plant_resources.id = production_runs.production_line_id
          LEFT JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_bins.rmt_container_material_type_id
          LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id;

      ALTER TABLE public.vw_rebin_label
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_rebin_label;
      CREATE VIEW public.vw_rebin_label AS
        SELECT
          rmt_bins.id,
          rmt_bins.bin_asset_number,
          rmt_bins.gross_weight,
          rmt_bins.nett_weight,
          rmt_bins.production_run_rebin_id AS production_run_id,
          farms.farm_code,
          orchards.orchard_code,
          pucs.puc_code,
          commodities.code AS commodity,
          commodities.description AS commodity_description,
          cultivars.cultivar_name,
          cultivars.description AS cultivar_description,
          cultivar_groups.cultivar_group_code,
          cultivar_groups.description AS cultivar_group_description,
          rmt_classes.rmt_class_code,
          rmt_classes.description AS rmt_class_description,
          to_char(rmt_bins.created_at AT TIME ZONE 'Africa/Johannesburg', 'YYYY-mm-dd HH24:MI'::text) AS created_at
        FROM
          rmt_bins
          LEFT JOIN farms ON farms.id = rmt_bins.farm_id
          LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
          LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
          LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
          LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
          LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
          LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id;

      ALTER TABLE public.vw_rebin_label
          OWNER TO postgres;
    SQL
  end
end
