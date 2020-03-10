Sequel.migration do
  up do
    # Function and triggers to update OTMC status for pallet_sequences
    # on create pallet_sequences and update orchard_test_results
    run <<~SQL
      --CREATE MATERIALIZED VIEW public.vw_failed_otmc_results AS
      CREATE VIEW public.vw_failed_otmc_results AS
      SELECT
          orchard_test_types.id AS test_type_id,
          orchard_test_types.test_type_code,
          orchard_test_types.description,
          orchard_test_types.api_name,
          orchard_test_types.result_type,
          orchard_test_types.result_attribute,
          orchard_test_results.puc_id,
          orchard_test_results.orchard_id,
          cultivars.id AS cultivar_id,
          orchard_test_results.passed,
          orchard_test_results.classification,
          orchard_test_results.classification_only,
          orchard_test_results.freeze_result,
          orchard_test_results.api_result,
          orchard_test_results.applicable_from,
          orchard_test_results.applicable_to,
          target_market_groups.id AS target_market_group_id,
          target_market_groups.target_market_group_name
      FROM orchard_test_types
      JOIN orchard_test_results ON orchard_test_types.id = orchard_test_results.orchard_test_type_id
      JOIN (SELECT
              orchard_test_types.id,
              (SELECT array_agg(id)  FROM target_market_groups) AS applicable_tm_group_ids
            FROM orchard_test_types
            WHERE applies_to_all_markets
            UNION
            SELECT
              orchard_test_types.id,
              applicable_tm_group_ids
            FROM orchard_test_types
            WHERE NOT applies_to_all_markets
          ) AS market_join ON orchard_test_types.id = market_join.id
      JOIN target_market_groups ON target_market_groups.id = ANY (market_join.applicable_tm_group_ids)
      JOIN (SELECT
              orchard_test_types.id,
               (select array_agg(id) from cultivars) AS applicable_cultivar_ids
            FROM orchard_test_types
            WHERE applies_to_all_cultivars
            UNION
            SELECT
              orchard_test_types.id,
              applicable_cultivar_ids
            FROM orchard_test_types
            WHERE NOT applies_to_all_cultivars) AS cultivar_join ON orchard_test_types.id = cultivar_join.id
      JOIN cultivars ON cultivars.id = ANY(cultivar_join.applicable_cultivar_ids)
      WHERE NOT orchard_test_results.classification_only
        AND NOT orchard_test_results.passed;

      ALTER TABLE public.vw_failed_otmc_results
      OWNER TO postgres;
    SQL

    # run <<~SQL
    #   CREATE FUNCTION public.refresh_vw_failed_otmc_results()
    #   RETURNS trigger LANGUAGE plpgsql
    #   AS $$
    #   BEGIN
    #     REFRESH MATERIALIZED VIEW vw_failed_otmc_results;
    #     RETURN NULL;
    #   END $$;
    # SQL

    run <<~SQL
      CREATE FUNCTION public.update_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET failed_otmc_results = sq.failed_otmc_results,
            pallet_failed_otmc_results = ARRAY(SELECT DISTINCT otmc_results FROM unnest(sq.pallet_failed_otmc_results || sq.failed_otmc_results) AS otmc_results)
        FROM (SELECT 
                ps.id,
                array_agg(DISTINCT v.test_type_id) AS failed_otmc_results,
                ps.pallet_failed_otmc_results AS pallet_failed_otmc_results
              FROM vw_failed_otmc_results v
              JOIN pallet_sequences ps 
                ON ps.puc_id = v.puc_id
             WHERE ps.orchard_id = v.orchard_id
               AND ps.cultivar_id = v.cultivar_id
               AND ps.packed_tm_group_id = v.target_market_group_id
             GROUP BY ps.id) AS sq
        WHERE ps.id = sq.id;
        RETURN new; 
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER INSERT
      ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();
    SQL

    # run <<~SQL
    #   CREATE FUNCTION public.refresh_update_otmc_results()
    #     RETURNS trigger AS
    #   $BODY$
    #   BEGIN
    #     PERFORM refresh_vw_failed_otmc_results();
    #     PERFORM update_pallet_sequences_failed_otmc_results();
    #     RETURN NULL;
    #   END;
    #   $BODY$
    #     LANGUAGE plpgsql
    #     COST 100;
    #   ALTER FUNCTION public.refresh_update_otmc_results()
    #     OWNER TO postgres;
    #
    #   CREATE TRIGGER refresh_update_otmc_results
    #   AFTER UPDATE OR DELETE
    #   ON orchard_test_types
    #   FOR EACH ROW
    #   EXECUTE PROCEDURE refresh_update_otmc_results();
    #
    #   CREATE TRIGGER refresh_update_otmc_results
    #   AFTER UPDATE OR DELETE
    #   ON orchard_test_results
    #   FOR EACH ROW
    #   EXECUTE PROCEDURE public.refresh_update_otmc_results();
    # SQL

    run <<~SQL
      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER UPDATE OR DELETE
      ON orchard_test_types
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();

      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER UPDATE OR DELETE
      ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.pallet_sequences;
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.orchard_test_types;
      DROP FUNCTION public.update_pallet_sequences_failed_otmc_results();
      DROP VIEW public.vw_failed_otmc_results;
    SQL

    # run <<~SQL
    #   DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.pallet_sequences;
    #   DROP TRIGGER refresh_update_otmc_results ON public.orchard_test_results;
    #   DROP TRIGGER refresh_update_otmc_results ON public.orchard_test_types;
    #   DROP FUNCTION public.refresh_update_otmc_results();
    #   DROP FUNCTION public.refresh_vw_failed_otmc_results();
    #   DROP FUNCTION public.update_pallet_sequences_failed_otmc_results();
    #   DROP MATERIALIZED VIEW public.vw_failed_otmc_results;
    # SQL
  end
end

