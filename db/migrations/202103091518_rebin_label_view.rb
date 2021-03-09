Sequel.migration do
  up do
    run <<~SQL
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
          to_char(rmt_bins.created_at AT TIME ZONE 'Africa/Johannesburg', 'YYYY-mm-dd HH24:MI'::text) AS created_at
        FROM
          rmt_bins
          LEFT JOIN farms ON farms.id = rmt_bins.farm_id
          LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
          LEFT JOIN cultivar_groups ON cultivar_groups.id = rmt_bins.cultivar_group_id
          LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
          LEFT JOIN commodities ON commodities.id = COALESCE(cultivars.commodity_id, cultivar_groups.commodity_id)
          LEFT JOIN rmt_classes ON rmt_classes.id = rmt_bins.rmt_class_id
          LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id;

      ALTER TABLE public.vw_rebin_label
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_bin_label;
    SQL
  end
end
