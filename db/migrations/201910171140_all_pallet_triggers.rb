Sequel.migration do
  up do
    # Function and triggers to update pallet nett_weight.
    # on pallets gross_weight update

    run <<~SQL
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

  down do
    run <<~SQL
      DROP TRIGGER pallets_update_gross_weight ON public.pallets;
      DROP FUNCTION public.fn_pallet_trigger_updates();
    SQL
  end
end
