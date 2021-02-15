Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_calculate_production_run_stats(
        in_id integer)
          RETURNS void
          LANGUAGE 'sql'

          COST 100
          VOLATILE 
          
      AS $BODY$
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
                                   FROM carton_labels
                                   WHERE carton_labels.production_run_id = production_run_stats.production_run_id
                                     AND EXISTS(SELECT id FROM cartons WHERE cartons.carton_label_id = carton_labels.id)),

               cartons_verified_weight = (SELECT COALESCE(SUM(COALESCE(cartons.nett_weight, 0)), 0)
                                           FROM carton_labels
                                           JOIN cartons ON cartons.carton_label_id = carton_labels.id
                                           WHERE carton_labels.production_run_id = production_run_stats.production_run_id),

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
      $BODY$;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_calculate_production_run_stats(
        in_id integer)
          RETURNS void
          LANGUAGE 'sql'

          COST 100
          VOLATILE 
          
      AS $BODY$
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
      $BODY$;
    SQL
  end
end
