Sequel.migration do
  up do
    run <<~SQL
      -- ==========================================================================
      -- Add production run id to queue (CARTON LABELS, CARTONS, PALLET SEQUECES)
      -- ==========================================================================

      CREATE OR REPLACE FUNCTION public.fn_add_run_to_stats_queue()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (NEW.production_run_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING NEW.production_run_id;
          END IF;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_run_to_stats_queue()
        OWNER TO postgres;


      -- ==========================================================================
      -- Add production run id to queue (RMT-BINS)
      -- ==========================================================================

      CREATE OR REPLACE FUNCTION public.fn_add_run_to_stats_queue_for_bin()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (NEW.production_run_tipped_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING NEW.production_run_tipped_id;
          END IF;

          IF (NEW.production_run_rebin_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING NEW.production_run_rebin_id;
          END IF;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_run_to_stats_queue_for_bin()
        OWNER TO postgres;


      -- ==========================================================================
      -- Triggers on tables to add to queue
      -- ==========================================================================

      CREATE TRIGGER rmt_bins_prod_run_stats_queue
      AFTER INSERT OR UPDATE OF bin_tipped, scrapped, nett_weight, qty_bins
      ON public.rmt_bins
      FOR EACH ROW
      EXECUTE PROCEDURE fn_add_run_to_stats_queue_for_bin();

      CREATE TRIGGER carton_labels_prod_run_stats_queue
      AFTER INSERT
      ON public.carton_labels
      FOR EACH ROW
      EXECUTE PROCEDURE fn_add_run_to_stats_queue();

      CREATE TRIGGER cartons_prod_run_stats_queue
      AFTER INSERT
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE fn_add_run_to_stats_queue();

      CREATE TRIGGER pallet_sequences_prod_run_stats_queue
      AFTER INSERT OR UPDATE OF carton_quantity, nett_weight, scrapped_at
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE fn_add_run_to_stats_queue();

      -- ==========================================================================
      -- Function to update PRDUCTION RUN STATS
      -- ==========================================================================

      CREATE OR REPLACE FUNCTION public.fn_calculate_production_run_stats(in_id integer)
        RETURNS void AS
      $BODY$
        UPDATE production_run_stats
           SET bins_tipped = (SELECT COALESCE(SUM(COALESCE(qty_bins, 0)), 0)
                               FROM rmt_bins
                               WHERE rmt_bins.production_run_tipped_id = production_run_stats.production_run_id
                               AND NOT scrapped),

               bins_tipped_weight = (SELECT COALESCE(SUM(COALESCE(nett_weight, 0)), 0)
                                     FROM rmt_bins
                                     WHERE rmt_bins.production_run_tipped_id = production_run_stats.production_run_id
                                     AND NOT scrapped),

               carton_labels_printed = (SELECT COUNT(*)
                                         FROM carton_labels
                                         WHERE carton_labels.production_run_id = production_run_stats.production_run_id),

               cartons_verified = (SELECT COUNT(*)
                                   FROM cartons
                                   WHERE cartons.production_run_id = production_run_stats.production_run_id),

               cartons_verified_weight = (SELECT COALESCE(SUM(COALESCE(nett_weight, 0)), 0)
                                           FROM cartons
                                           WHERE cartons.production_run_id = production_run_stats.production_run_id),

               pallets_palletized_full = (SELECT COUNT(DISTINCT pallets.id)
                                           FROM pallets
                                           JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
                                           WHERE pallet_sequences.production_run_id = production_run_stats.production_run_id
                                           AND palletized
                                           AND NOT pallets.scrapped),

               pallets_palletized_partial = (SELECT COUNT(DISTINCT pallets.id)
                                             FROM pallets
                                             JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
                                             WHERE pallet_sequences.production_run_id = production_run_stats.production_run_id
                                             AND partially_palletized
                                             AND NOT pallets.scrapped),

               inspected_pallets = (SELECT COUNT(DISTINCT pallets.id)
                                     FROM pallets
                                     JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
                                     WHERE pallet_sequences.production_run_id = production_run_stats.production_run_id
                                     AND inspected
                                     AND NOT pallets.scrapped),

               rebins_created = (SELECT COUNT(*)
                                 FROM rmt_bins
                                 WHERE rmt_bins.production_run_rebin_id = production_run_stats.production_run_id
                                 AND NOT scrapped),

               rebins_weight = (SELECT COALESCE(SUM(COALESCE(nett_weight, 0)), 0)
                                 FROM rmt_bins where rmt_bins.production_run_rebin_id = production_run_stats.production_run_id
                                 AND NOT scrapped)
        WHERE production_run_id = in_id;
      $BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_calculate_production_run_stats(integer)
        OWNER TO postgres;

      -- ==========================================================================
      -- Function to work through prodrun stats queue
      -- Invoke from cron like this:
      -- PGPASSWORD=xxxx psql -v ON_ERROR_STOP=1 -c 'SELECT fn_production_run_stats_queue_worker();' -d nspack -U postgres
      -- ==========================================================================

      CREATE OR REPLACE FUNCTION public.fn_production_run_stats_queue_worker()
        RETURNS integer AS
      $BODY$
        DECLARE
          p_queue_ids INTEGER[];
          p_run_ids INTEGER[];
          i INTEGER;
          array_len INTEGER;
          this_run_id INTEGER;
        BEGIN
          EXECUTE 'SELECT array(SELECT id FROM production_run_stats_queue)' INTO p_queue_ids;

          IF (array_length(p_queue_ids, 1) > 0) THEN
            EXECUTE 'SELECT array(SELECT DISTINCT production_run_id FROM production_run_stats_queue WHERE id = ANY($1))' INTO p_run_ids USING p_queue_ids;
            array_len = array_length(p_run_ids, 1);
            FOR i IN 1 .. array_len
            LOOP
              this_run_id = p_run_ids[i];
              EXECUTE 'SELECT fn_calculate_production_run_stats($1)' USING this_run_id;
            END LOOP;

            EXECUTE 'DELETE FROM production_run_stats_queue WHERE id = ANY($1)' USING p_queue_ids;

            RETURN array_length(p_run_ids, 1);
          ELSE
            RETURN 0;
          END IF;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_production_run_stats_queue_worker()
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER rmt_bins_prod_run_stats_queue ON rmt_bins;
      DROP TRIGGER carton_labels_prod_run_stats_queue ON carton_labels;
      DROP TRIGGER cartons_prod_run_stats_queue ON cartons;
      DROP TRIGGER pallet_sequences_prod_run_stats_queue ON pallet_sequences;

      DROP FUNCTION public.fn_add_run_to_stats_queue_for_bin();
      DROP FUNCTION public.fn_add_run_to_stats_queue();

      DROP FUNCTION public.fn_production_run_stats_queue_worker();
      DROP FUNCTION public.fn_calculate_production_run_stats(integer);
    SQL
  end
end
