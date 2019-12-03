Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_add_run_to_stats_queue()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (NEW.production_run_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO production_run_stats_queue (production_run_id) VALUES($1);' USING NEW.production_run_id;
          END IF;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_run_to_stats_queue()
        OWNER TO postgres;


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
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_run_to_stats_queue_for_bin()
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
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
    SQL
  end
end
