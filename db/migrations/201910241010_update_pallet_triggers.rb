Sequel.migration do
  up do
    # Function and triggers to update pallet nett_weight.
    # on pallets gross_weight, scrapped, build_status and inspected update

    run <<~SQL
      DROP TRIGGER pallets_update_gross_weight ON public.pallets;
      DROP FUNCTION public.fn_pallet_trigger_updates();

      CREATE OR REPLACE FUNCTION public.fn_pallet_trigger_updates()
        RETURNS trigger AS
      $BODY$
        DECLARE
          plt_carton_quantity DECIMAL;
          plt_first_ps INTEGER;
          plt_first_ps_pdn_run_id INTEGER;
        BEGIN
          EXECUTE 'SELECT carton_quantity FROM pallets WHERE id = $1'
          INTO plt_carton_quantity
          USING NEW.id;

          EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   WHERE NOT pallets.scrapped AND pallets.id = $1'
          INTO plt_first_ps
          USING NEW.id;

          EXECUTE 'SELECT production_run_id FROM pallet_sequences
                   WHERE pallet_id = $1 AND pallet_sequence_number = $2'
          INTO plt_first_ps_pdn_run_id
          USING NEW.id, plt_first_ps;

          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.gross_weight IS NULL AND NEW.gross_weight IS NOT NULL) OR (NEW.gross_weight <> OLD.gross_weight) THEN
              NEW.nett_weight = fn_calculate_pallet_nett_weight(OLD.id, NEW.gross_weight);
              EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2) * $3
                       WHERE pallet_id = $1'
              USING NEW.id, plt_carton_quantity, NEW.nett_weight;         
            END IF;

            IF (NEW.scrapped <> OLD.scrapped) THEN
              IF (NEW.scrapped IS TRUE) THEN
                IF (NEW.palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_full = (pallets_palletized_full - 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                ELSIF (NEW.partially_palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial - 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                END IF;
              ELSIF (NEW.scrapped IS NOT TRUE) THEN
                IF (NEW.palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_full = (pallets_palletized_full + 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                ELSIF (NEW.partially_palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial + 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                END IF;
              END IF;
            END IF;

            IF (OLD.build_status IS NULL AND NEW.build_status IS NOT NULL) OR (NEW.build_status <> OLD.build_status) THEN
              CASE NEW.build_status
                WHEN 'FULL' THEN
                  EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial - 1),
                           pallets_palletized_full = (pallets_palletized_full + 1)
                           WHERE production_run_id = $1'
                  USING plt_first_ps_pdn_run_id;
                WHEN 'PARTIAL', 'OVERFULL' THEN
                  IF (OLD.build_status = 'FULL'::text) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial + 1),
                             pallets_palletized_full = (pallets_palletized_full - 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                  END IF;
              END CASE;
            END IF;

            IF (NEW.inspected <> OLD.inspected) THEN
              IF (NEW.inspected IS TRUE) THEN
                EXECUTE 'UPDATE production_run_stats SET inspected_pallets = (inspected_pallets + 1)
                         WHERE production_run_id = $1'
                USING plt_first_ps_pdn_run_id;
              ELSIF (NEW.inspected IS NOT TRUE) THEN
                EXECUTE 'UPDATE production_run_stats SET inspected_pallets = (inspected_pallets - 1)
                         WHERE production_run_id = $1'
                USING plt_first_ps_pdn_run_id;
              END IF;
            END IF;

          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_trigger_updates()
        OWNER TO postgres;

      CREATE TRIGGER pallets_update_gross_weight
      BEFORE UPDATE OF gross_weight
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_before_update_scrapped
      BEFORE UPDATE OF scrapped
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_after_update_scrapped
      AFTER UPDATE OF scrapped
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_update_build_status
      AFTER UPDATE OF build_status
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_update_inspected
      AFTER UPDATE OF inspected
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER pallets_update_gross_weight ON public.pallets;
      DROP TRIGGER pallets_before_update_scrapped ON public.pallets;
      DROP TRIGGER pallets_after_update_scrapped ON public.pallets;
      DROP TRIGGER pallets_update_build_status ON public.pallets;
      DROP TRIGGER pallets_update_inspected ON public.pallets;
      DROP FUNCTION public.fn_pallet_trigger_updates();

      CREATE OR REPLACE FUNCTION public.fn_pallet_trigger_updates()
        RETURNS trigger AS
      $BODY$
        DECLARE
        BEGIN
          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.gross_weight IS NULL AND NEW.gross_weight IS NOT NULL) OR (NEW.gross_weight <> OLD.gross_weight) THEN
              NEW.nett_weight = fn_calculate_pallet_nett_weight(OLD.id, NEW.gross_weight);
            END IF;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_trigger_updates()
        OWNER TO postgres;

      CREATE TRIGGER pallets_update_gross_weight
      BEFORE UPDATE OF gross_weight
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();
    SQL
  end
end
