Sequel.migration do
  up do
    run <<~SQL
      -- ==============================
      -- Monitors rmt_bins.location_id
      -- ==============================

      CREATE OR REPLACE FUNCTION public.fn_bin_check_if_location_has_changed()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (TG_OP = 'DELETE') THEN
            IF (OLD.location_id IS NOT NULL) THEN
              EXECUTE 'UPDATE locations SET units_in_location = (units_in_location - 1) WHERE id = $1' USING OLD.location_id;
            END IF;            
          ELSIF (TG_OP = 'UPDATE') THEN
            EXECUTE 'UPDATE locations SET units_in_location = (units_in_location - 1) WHERE id = $1' USING OLD.location_id;
            EXECUTE 'UPDATE locations SET units_in_location = (units_in_location + 1) WHERE id = $1' USING NEW.location_id;
          ELSIF (TG_OP = 'INSERT') THEN
            IF (NEW.location_id IS NOT NULL) THEN
              EXECUTE 'UPDATE locations SET units_in_location = (units_in_location + 1) WHERE id = $1' USING NEW.location_id;
            END IF;
          END IF;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_bin_check_if_location_has_changed()
        OWNER TO postgres;

      -- ===========================
      -- Monitors rmt_bins.exit_ref
      -- ===========================

      CREATE OR REPLACE FUNCTION public.fn_bin_check_if_exit_ref_has_changed()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (TG_OP = 'UPDATE') THEN
            IF (NEW.exit_ref IS NULL AND NEW.location_id IS NOT NULL) THEN
              EXECUTE 'UPDATE locations SET units_in_location = (units_in_location + 1) WHERE id = $1' USING NEW.location_id;
            ELSIF (NEW.exit_ref IS NOT NULL AND NEW.location_id IS NOT NULL) THEN
              EXECUTE 'UPDATE locations SET units_in_location = (units_in_location - 1) WHERE id = $1' USING NEW.location_id;
            END IF;
          END IF;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_bin_check_if_exit_ref_has_changed()
        OWNER TO postgres;

      CREATE TRIGGER rmt_bins_check_location_on_create_and_delete
        AFTER INSERT OR DELETE
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_bin_check_if_location_has_changed();

      CREATE TRIGGER rmt_bins_check_if_location_has_changed
        AFTER UPDATE OF location_id
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_bin_check_if_location_has_changed();
      CREATE TRIGGER rmt_bins_check_if_exit_ref_has_changed
        AFTER UPDATE OF exit_ref
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_bin_check_if_exit_ref_has_changed();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER rmt_bins_check_location_on_create_and_delete ON public.rmt_bins;
      DROP TRIGGER rmt_bins_check_if_location_has_changed ON public.rmt_bins;
      DROP TRIGGER rmt_bins_check_if_exit_ref_has_changed ON public.rmt_bins;

      DROP FUNCTION public.fn_bin_check_if_location_has_changed();
      DROP FUNCTION public.fn_bin_check_if_exit_ref_has_changed();
    SQL
  end
end
