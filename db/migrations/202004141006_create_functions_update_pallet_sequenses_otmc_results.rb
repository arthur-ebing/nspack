Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION public.insert_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET failed_otmc_results = (SELECT array_agg(test_type_id) as failed_otmc_results
                                   FROM vw_orchard_test_results_flat
                                   WHERE NEW.puc_id = ANY(puc_ids)
                                   AND NEW.orchard_id = ANY(orchard_ids)
                                   AND NEW.cultivar_id = ANY(cultivar_ids)
                                   AND NEW.packed_tm_group_id = ANY(tm_group_ids)
                                   AND NOT passed)
        WHERE ps.id = NEW.id
          AND ps.exit_ref IS NULL;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER insert_pallet_sequences_failed_otmc_results
      AFTER INSERT
      ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE insert_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      CREATE FUNCTION public.update_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET failed_otmc_results = (SELECT
                                      CASE
                                        WHEN array_agg(vw.test_type_id) = '{null}' THEN NULL
                                        ELSE array_agg(vw.test_type_id)
                                      END
                                    FROM vw_orchard_test_results_flat vw
                                    WHERE pallet_sequences.puc_id = ANY(vw.puc_ids)
                                      AND pallet_sequences.orchard_id = ANY(vw.orchard_ids)
                                      AND pallet_sequences.cultivar_id = ANY(vw.cultivar_ids)
                                      AND pallet_sequences.packed_tm_group_id = ANY(vw.tm_group_ids)
                                      AND NOT vw.passed)
        WHERE pallet_sequences.puc_id = NEW.puc_id
          AND pallet_sequences.orchard_id = NEW.orchard_id
          AND pallet_sequences.cultivar_id = NEW.cultivar_id
          AND pallet_sequences.exit_ref IS NULL;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER UPDATE
      ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      CREATE FUNCTION public.delete_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET failed_otmc_results = (SELECT
                                      CASE
                                        WHEN array_agg(vw.test_type_id) = '{null}' THEN NULL
                                        ELSE array_agg(vw.test_type_id)
                                      END
                                    FROM vw_orchard_test_results_flat vw
                                    WHERE pallet_sequences.puc_id = ANY(vw.puc_ids)
                                      AND pallet_sequences.orchard_id = ANY(vw.orchard_ids)
                                      AND pallet_sequences.cultivar_id = ANY(vw.cultivar_ids)
                                      AND pallet_sequences.packed_tm_group_id = ANY(vw.tm_group_ids)
                                      AND NOT vw.passed)
        WHERE pallet_sequences.puc_id = OLD.puc_id
          AND pallet_sequences.orchard_id = OLD.orchard_id
          AND pallet_sequences.cultivar_id = OLD.cultivar_id
          AND pallet_sequences.exit_ref IS NULL;
        RETURN null;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER delete_pallet_sequences_failed_otmc_results
      AFTER DELETE
      ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE delete_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      CREATE FUNCTION public.update_all_pallet_sequences_failed_otmc_results()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET failed_otmc_results = sq.failed_otmc_results
        FROM (SELECT
                CASE
                  WHEN array_agg(vw.test_type_id) = '{null}' THEN NULL
                  ELSE array_agg(vw.test_type_id)
                END AS failed_otmc_results,
                ps.id
              FROM pallet_sequences ps
              LEFT JOIN vw_orchard_test_results_flat vw
              ON  ps.puc_id = ANY(vw.puc_ids)
              AND ps.orchard_id = ANY(vw.orchard_ids)
              AND ps.cultivar_id = ANY(vw.cultivar_ids)
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids)
              AND NOT vw.passed
              WHERE vw.test_type_id = NEW.id
              GROUP BY ps.id) AS sq
        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.exit_ref IS NULL;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_all_pallet_sequences_failed_otmc_results
      AFTER UPDATE
      ON orchard_test_types
      FOR EACH ROW
      EXECUTE PROCEDURE update_all_pallet_sequences_failed_otmc_results();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER update_all_pallet_sequences_failed_otmc_results ON public.orchard_test_types;
      DROP FUNCTION public.update_all_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      DROP TRIGGER delete_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP FUNCTION public.delete_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP FUNCTION public.update_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      DROP TRIGGER insert_pallet_sequences_failed_otmc_results ON public.pallet_sequences;
      DROP FUNCTION public.insert_pallet_sequences_failed_otmc_results();
    SQL
  end
end
