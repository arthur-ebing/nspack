# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_add_changed_runs_to_stats_queue()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (OLD.production_run_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING OLD.production_run_id;
          END IF;

          IF (NEW.production_run_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING NEW.production_run_id;
          END IF;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_changed_runs_to_stats_queue()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_prod_run_changed_stats_queue
        BEFORE UPDATE OF production_run_id
        ON public.pallet_sequences
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_add_changed_runs_to_stats_queue();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER pallet_sequences_prod_run_changed_stats_queue;
      DROP FUNCTION public.fn_add_changed_runs_to_stats_queue();
    SQL
  end
end
