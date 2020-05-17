Sequel.migration do
  up do
    run <<~SQL
      DROP TRIGGER delete_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP FUNCTION public.delete_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.pallet_sequences;
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.orchard_test_results;
      DROP FUNCTION public.update_pallet_sequences_failed_otmc_results();
    SQL

    run <<~SQL
      DROP VIEW public.vw_orchard_test_results_flat;
      CREATE VIEW public.vw_orchard_test_results_flat AS
        SELECT DISTINCT
          otr.id,
          ott.id AS test_type_id,
          ott.test_type_code,
          ott.description,
          otr.classification,
          otr.passed,
          otr.api_result,
          ott.api_pass_result,
          ott.api_default_result,
          otr.freeze_result,
          otr.applicable_from,
          otr.applicable_to,
          ott.api_name,
          ott.api_attribute,
          otr.puc_id,
          pucs.puc_code,
          otr.orchard_id,
          orchards.orchard_code,
          otr.cultivar_id,
          cultivars.cultivar_code,
          otr.active,
          otr.created_at,
          otr.updated_at,

          CASE
            WHEN ott.applies_to_all_markets THEN (SELECT array_agg(tmg.id ORDER BY tmg.id) AS array_agg  FROM target_market_groups tmg)
            ELSE ott.applicable_tm_group_ids
          END AS tm_group_ids,
          CASE
            WHEN ott.applies_to_all_markets THEN (SELECT string_agg(tmg.target_market_group_name::text, ', ' ORDER BY tmg.target_market_group_name) AS string_agg FROM target_market_groups tmg)
            ELSE (SELECT string_agg(tmg.target_market_group_name::text, ', ' ORDER BY tmg.target_market_group_name) AS string_agg FROM target_market_groups tmg WHERE tmg.id = ANY (ott.applicable_tm_group_ids))
          END AS tm_group_codes

        FROM orchard_test_types ott
        JOIN orchard_test_results otr ON ott.id = otr.orchard_test_type_id
        JOIN pucs ON otr.puc_id = pucs.id
        JOIN orchards ON otr.orchard_id = orchards.id
        JOIN cultivars ON otr.cultivar_id = cultivars.id

        ORDER BY otr.puc_id, otr.orchard_id, otr.cultivar_id;

      ALTER TABLE public.vw_orchard_test_results_flat
      OWNER TO postgres;
    SQL

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
                  array_agg(vw.test_type_id order by vw.test_type_id) filter (where vw.test_type_id is not null) AS new_failed_otmc_results
              
              FROM pallet_sequences ps
              JOIN pallets p ON p.id = ps.pallet_id
              LEFT JOIN (SELECT * FROM vw_orchard_test_results_flat WHERE NOT passed AND NOT classification) vw
              ON  ps.puc_id = vw.puc_id
              AND ps.orchard_id = vw.orchard_id
              AND ps.cultivar_id = vw.cultivar_id
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids)
              
              WHERE p.exit_ref IS NULL
              GROUP BY ps.id) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.failed_otmc_results IS DISTINCT FROM sq.new_failed_otmc_results
          AND pallet_sequences.puc_id = NEW.puc_id
          AND pallet_sequences.orchard_id = NEW.orchard_id
          AND pallet_sequences.cultivar_id = NEW.cultivar_id;
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
                  ps.failed_otmc_results,
                  array_agg(vw.test_type_id order by vw.test_type_id) filter (where vw.test_type_id is not null) AS new_failed_otmc_results
              
              FROM pallet_sequences ps
              JOIN pallets p ON p.id = ps.pallet_id
              LEFT JOIN (SELECT * FROM vw_orchard_test_results_flat WHERE NOT passed AND NOT classification) vw
              ON  ps.puc_id = vw.puc_id
              AND ps.orchard_id = vw.orchard_id
              AND ps.cultivar_id = vw.cultivar_id
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids)
              
              WHERE p.exit_ref IS NULL
              GROUP BY ps.id) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.failed_otmc_results IS DISTINCT FROM sq.new_failed_otmc_results
          AND pallet_sequences.puc_id = OLD.puc_id
          AND pallet_sequences.orchard_id = OLD.orchard_id
          AND pallet_sequences.cultivar_id = OLD.cultivar_id;
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

    run <<~SQL
      DROP VIEW public.vw_orchard_test_results_flat;
      CREATE VIEW public.vw_orchard_test_results_flat AS
        SELECT DISTINCT
          ott.id AS test_type_id,
          ott.test_type_code,
          ott.description,
          otr.classification,
          otr.passed,
          otr.api_result,
          ott.api_pass_result,
          ott.api_default_result,
          otr.freeze_result,
          otr.applicable_from,
          otr.applicable_to,
          ott.api_name,
          ott.api_attribute,
          array_agg(distinct otr.id order by otr.id) AS orchard_test_results_ids,
          array_agg(distinct otr.puc_id order by otr.puc_id) AS puc_ids,
          string_agg(distinct pucs.puc_code, ', ' order by pucs.puc_code) AS puc_codes,
          array_agg(distinct otr.orchard_id order by otr.orchard_id) AS orchard_ids,
          string_agg(distinct orchards.orchard_code, ', ' order by orchards.orchard_code) AS orchards_codes,
          array_agg(distinct otr.cultivar_id order by otr.cultivar_id) AS cultivar_ids,
          string_agg(distinct cultivars.cultivar_code, ', ' order by cultivars.cultivar_code) AS cultivar_codes,
      
          CASE
              WHEN ott.applies_to_all_markets THEN (SELECT array_agg(tmg.id) FROM target_market_groups tmg)
              ELSE ott.applicable_tm_group_ids
              END AS tm_group_ids,
          CASE
              WHEN ott.applies_to_all_markets THEN (SELECT string_agg(tmg.target_market_group_name , ', ') FROM target_market_groups tmg)
              ELSE (SELECT string_agg(tmg.target_market_group_name , ', ') FROM target_market_groups tmg WHERE tmg.id = ANY (ott.applicable_tm_group_ids))
              END AS tm_group_codes
      
        FROM orchard_test_types ott
        JOIN orchard_test_results otr ON ott.id = otr.orchard_test_type_id
        JOIN pucs ON otr.puc_id = pucs.id
        JOIN orchards ON otr.orchard_id = orchards.id
        JOIN cultivars ON otr.cultivar_id = cultivars.id
        
        GROUP BY
            ott.id,
            otr.passed,
            otr.api_result,
            otr.classification,
            otr.freeze_result,
            otr.applicable_from,
            otr.applicable_to;

      ALTER TABLE public.vw_orchard_test_results_flat
      OWNER TO postgres;
    SQL

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
              JOIN pallets p ON p.id = ps.pallet_id
              LEFT JOIN (SELECT * FROM vw_orchard_test_results_flat WHERE NOT passed AND NOT classification) vw
              ON (ps.puc_id = ANY(vw.puc_ids)
              AND ps.orchard_id = ANY(vw.orchard_ids)
              AND ps.cultivar_id = ANY(vw.cultivar_ids)
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids))
              
              WHERE p.exit_ref IS NULL
              GROUP BY ps.id) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.failed_otmc_results IS DISTINCT FROM sq.new_failed_otmc_results;
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
              JOIN pallets p ON p.id = ps.pallet_id
              LEFT JOIN (SELECT * FROM vw_orchard_test_results_flat WHERE NOT passed AND NOT classification) vw
               ON ps.puc_id = ANY(vw.puc_ids)
              AND ps.orchard_id = ANY(vw.orchard_ids)
              AND ps.cultivar_id = ANY(vw.cultivar_ids)
              AND ps.packed_tm_group_id = ANY(vw.tm_group_ids)
              
              WHERE p.exit_ref IS NULL 
              GROUP BY ps.id) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.failed_otmc_results IS DISTINCT FROM sq.new_failed_otmc_result;
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
end

