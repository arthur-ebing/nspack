Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.update_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET failed_otmc_results = sq.failed_otmc_results
        FROM (
          SELECT
              ps.id,
              CASE
                  WHEN array_agg(DISTINCT v.test_type_id) = '{null}'
                  THEN NULL
                  ELSE array_agg(DISTINCT v.test_type_id)
              END AS failed_otmc_results
          FROM pallet_sequences ps
          LEFT JOIN vw_failed_otmc_results v ON ps.puc_id = v.puc_id
          AND ps.orchard_id = v.orchard_id
          AND ps.cultivar_id = v.cultivar_id
          AND ps.packed_tm_group_id = v.target_market_group_id
          WHERE ps.failed_otmc_results IS NOT NULL
          AND ps.exit_ref IS NULL
          GROUP BY ps.id
          UNION
          SELECT
              ps.id,
              CASE
                  WHEN array_agg(DISTINCT v.test_type_id) = '{null}'
                  THEN NULL
                  ELSE array_agg(DISTINCT v.test_type_id)
              END AS failed_otmc_results
          FROM pallet_sequences ps
              JOIN vw_failed_otmc_results v ON ps.puc_id = v.puc_id
              AND ps.orchard_id = v.orchard_id
              AND ps.cultivar_id = v.cultivar_id
              AND ps.packed_tm_group_id = v.target_market_group_id
          WHERE ps.exit_ref IS NULL
          GROUP BY ps.id
        ) AS sq
        WHERE ps.id = sq.id;
        RETURN new; 
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.update_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET failed_otmc_results = sq.failed_otmc_results
        FROM (
          SELECT
              ps.id,
              CASE
                  WHEN array_agg(DISTINCT v.test_type_id) = '{null}'
                  THEN NULL
                  ELSE array_agg(DISTINCT v.test_type_id)
              END AS failed_otmc_results
          FROM pallet_sequences ps
          LEFT JOIN vw_failed_otmc_results v ON ps.puc_id = v.puc_id
          AND ps.orchard_id = v.orchard_id
          AND ps.cultivar_id = v.cultivar_id
          AND ps.packed_tm_group_id = v.target_market_group_id
          WHERE ps.failed_otmc_results IS NOT NULL
          GROUP BY ps.id
          UNION
          SELECT
              ps.id,
              CASE
                  WHEN array_agg(DISTINCT v.test_type_id) = '{null}'
                  THEN NULL
                  ELSE array_agg(DISTINCT v.test_type_id)
              END AS failed_otmc_results
          FROM pallet_sequences ps
              JOIN vw_failed_otmc_results v ON ps.puc_id = v.puc_id
              AND ps.orchard_id = v.orchard_id
              AND ps.cultivar_id = v.cultivar_id
              AND ps.packed_tm_group_id = v.target_market_group_id
          GROUP BY ps.id
        ) AS sq
        WHERE ps.id = sq.id;
        RETURN new; 
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    SQL
  end
end

