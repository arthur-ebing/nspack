Sequel.migration do
  up do
    # Function and triggers to update production_run_stats rebins_created and rebins_weight
    # on rebin insert

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.update_prod_run_stats_rebins_created()
        RETURNS trigger AS
      $BODY$
        DECLARE
        BEGIN
          IF (TG_OP = 'INSERT') THEN
            IF (NEW.is_rebin IS TRUE) THEN
              UPDATE production_run_stats set rebins_created=rebins_created+1, rebins_weight=rebins_weight+NEW.nett_weight WHERE production_run_id = NEW.production_run_rebin_id;
            END IF;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.update_prod_run_stats_rebins_created()
        OWNER TO postgres;

      CREATE TRIGGER rebins_created_prod_run_stats_trigger_updates
      AFTER INSERT
      ON public.rmt_bins
      FOR EACH ROW
      EXECUTE PROCEDURE public.update_prod_run_stats_rebins_created();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER rebins_created_prod_run_stats_trigger_updates ON public.rmt_bins;
      DROP FUNCTION public.update_prod_run_stats_rebins_created();
    SQL
  end
end
