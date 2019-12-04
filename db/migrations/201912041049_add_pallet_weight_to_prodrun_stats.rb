Sequel.migration do
  up do
    alter_table(:production_run_stats) do
      add_column :pallet_weight, BigDecimal, default: 0
    end

    run <<~SQL
      -- ========================================
      -- Add production run id to queue (PALLETS)
      -- ========================================

      CREATE OR REPLACE FUNCTION public.fn_add_run_to_stats_queue_for_pallet()
        RETURNS trigger AS
      $BODY$
        DECLARE
          production_run_id INTEGER;
        BEGIN
          EXECUTE 'SELECT production_run_id FROM pallet_sequences WHERE pallet_id = $1 LIMIT 1;' INTO production_run_id USING NEW.id;

          IF (production_run_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING production_run_id;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_run_to_stats_queue_for_pallet()
        OWNER TO postgres;

      CREATE TRIGGER pallets_prod_run_stats_queue
      AFTER UPDATE OF scrapped_at
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE fn_add_run_to_stats_queue_for_pallet();
    SQL

    run <<~SQL
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

               pallet_weight = (SELECT COALESCE(SUM(COALESCE(pallet_sequences.nett_weight, 0)), 0)
                                             FROM pallet_sequences
                                             JOIN pallets ON pallets.id = pallet_sequences.pallet_id
                                             WHERE pallet_sequences.production_run_id = production_run_stats.production_run_id
                                               AND pallet_sequences.scrapped_at IS NULL
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
    SQL
  end

  down do
    alter_table(:production_run_stats) do
      drop_column :pallet_weight
    end

    run <<~SQL
      DROP TRIGGER pallets_prod_run_stats_queue ON pallets;
      DROP FUNCTION public.fn_add_run_to_stats_queue_for_pallet();
    SQL

    run <<~SQL
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
    SQL
  end
end
