Sequel.migration do
  up do
    # Function and triggers to update pallet build_status, nett_weight, carton_quantity and pallet_sequences nett_weight.
    # on pallet_sequences insert and update

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_ps_pallet_trigger_updates()
        RETURNS trigger AS
      $BODY$
        DECLARE
          plt_ps_carton_quantity DECIMAL;
          plt_first_ps INTEGER;
          cartons_per_pallet INTEGER;
          plt_carton_quantity DECIMAL;
          plt_build_status TEXT;
          ps_nett_weight DECIMAL;
          
        BEGIN
          EXECUTE 'SELECT sum(carton_quantity) FROM pallet_sequences WHERE pallet_id = $1'
          INTO plt_ps_carton_quantity
          USING NEW.pallet_id;

          IF (plt_ps_carton_quantity IS NULL) THEN
            plt_carton_quantity = NEW.carton_quantity;
          ELSE
            plt_carton_quantity = plt_ps_carton_quantity + NEW.carton_quantity;
          END IF;

          IF (plt_carton_quantity IS NULL) THEN
              RAISE EXCEPTION 'Cannot calculate a build_status. There is no plt_carton_quantity set';
          END IF;

          EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   WHERE NOT pallets.scrapped AND pallets.id = $1'
          INTO plt_first_ps
          USING NEW.pallet_id;

          IF (plt_first_ps IS NOT NULL) THEN
            EXECUTE 'SELECT cartons_per_pallet FROM cartons_per_pallet
                     JOIN pallet_sequences ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
                     WHERE pallet_sequences.id = $1'
            INTO cartons_per_pallet
            USING plt_first_ps;
          END IF; 

          IF (cartons_per_pallet IS NULL) THEN
            EXECUTE 'SELECT cartons_per_pallet FROM cartons_per_pallet
                     WHERE cartons_per_pallet.id = $1'
            INTO cartons_per_pallet
            USING NEW.cartons_per_pallet_id; 
          END IF; 

          IF (cartons_per_pallet IS NULL) THEN
              RAISE EXCEPTION 'Cannot calculate a build_status. There is no cartons_per_pallet set';
          END IF;

          plt_build_status = fn_calculate_pallet_build_status(plt_carton_quantity, cartons_per_pallet);
          ps_nett_weight = NEW.carton_quantity / plt_carton_quantity;

          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.carton_quantity IS NULL AND NEW.carton_quantity IS NOT NULL) OR (NEW.carton_quantity <> OLD.carton_quantity) THEN
              CASE plt_build_status
                WHEN 'FULL' THEN
                  EXECUTE 'UPDATE pallets SET build_status = $2, palletized = true, palletized_at = $3, carton_quantity = $4
                           WHERE id = $1'
                  USING NEW.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
                WHEN 'PARTIAL', 'OVERFULL' THEN
                  EXECUTE 'UPDATE pallets SET build_status = $2, partially_palletized = true, partially_palletized_at = $3, carton_quantity = $4
                           WHERE id = $1'
                  USING NEW.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
              END CASE;
              EXECUTE 'UPDATE pallet_sequences SET nett_weight = $2 WHERE id = $1'
              USING NEW.id, ps_nett_weight;
            END IF;
          ELSIF (TG_OP = 'INSERT') THEN
            CASE plt_build_status
              WHEN 'FULL' THEN
                EXECUTE 'UPDATE pallets SET build_status = $2, palletized = true, palletized_at = $3, carton_quantity = $4
                         WHERE id = $1'
                USING NEW.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
              WHEN 'PARTIAL', 'OVERFULL' THEN
                EXECUTE 'UPDATE pallets SET build_status = $2, partially_palletized = true, partially_palletized_at = $3, carton_quantity = $4
                         WHERE id = $1'
                USING NEW.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
            END CASE;
            EXECUTE 'UPDATE pallet_sequences SET nett_weight = $2 WHERE id = $1'
            USING NEW.id, ps_nett_weight;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_ps_pallet_trigger_updates()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_pallets_trigger_updates
      BEFORE INSERT
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_ps_pallet_trigger_updates();

      CREATE TRIGGER pallet_sequences_update_carton_quantity
      AFTER UPDATE OF carton_quantity
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_ps_pallet_trigger_updates();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER pallet_sequences_pallets_trigger_updates ON public.pallet_sequences;
      DROP TRIGGER pallet_sequences_update_carton_quantity ON public.pallet_sequences;
      DROP FUNCTION public.fn_ps_pallet_trigger_updates();
    SQL
  end
end
