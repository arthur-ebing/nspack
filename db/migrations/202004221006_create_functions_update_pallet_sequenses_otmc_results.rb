Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION public.update_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET failed_otmc_results = sq.new_failed_otmc_results
        FROM (SELECT
                  ps.id,
                  ps.failed_otmc_results,
                  CASE
                      WHEN array_agg(vw.test_type_id) = '{null}' THEN NULL
                      ELSE array_agg(vw.test_type_id)
                  END AS new_failed_otmc_results
              
              FROM pallet_sequences ps
              LEFT JOIN (SELECT * FROM vw_orchard_test_results_flat WHERE NOT passed AND NOT classification) vw
              ON (ps.puc_id = ANY(vw.puc_ids)
              AND ps.orchard_id = ANY(vw.orchard_ids)
              AND ps.cultivar_id = ANY(vw.cultivar_ids)
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids))
              
              WHERE ps.exit_ref IS NULL
              GROUP BY ps.id) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.failed_otmc_results IS DISTINCT FROM sq.new_failed_otmc_results
        ;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER INSERT OR UPDATE ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();

      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER INSERT OR UPDATE OF puc_id, orchard_id, cultivar_id, packed_tm_group_id ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      CREATE FUNCTION public.delete_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET failed_otmc_results = sq.new_failed_otmc_results
        FROM (SELECT
                  ps.id,
                  CASE
                      WHEN array_agg(vw.test_type_id) = '{null}' THEN NULL
                      ELSE array_agg(vw.test_type_id)
                  END AS new_failed_otmc_results
              
              FROM pallet_sequences ps
              LEFT JOIN (SELECT * FROM vw_orchard_test_results_flat WHERE NOT passed AND NOT classification) vw
               ON ps.puc_id = ANY(vw.puc_ids)
              AND ps.orchard_id = ANY(vw.orchard_ids)
              AND ps.cultivar_id = ANY(vw.cultivar_ids)
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids)
              
              WHERE ps.exit_ref IS NULL 
              GROUP BY ps.id) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.failed_otmc_results IS DISTINCT FROM sq.new_failed_otmc_results
;
        RETURN NULL;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER delete_pallet_sequences_failed_otmc_results
      AFTER DELETE ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE delete_pallet_sequences_failed_otmc_results();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER delete_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP FUNCTION public.delete_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.pallet_sequences;
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP FUNCTION public.update_pallet_sequences_failed_otmc_results();
    SQL
  end
end
