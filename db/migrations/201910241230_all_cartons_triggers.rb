Sequel.migration do
  up do
    # Function and triggers to update production_run_stats cartons_verified and cartons_verified_weight on cartons insert
    # and cartons_verified_weight on update

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.update_prod_run_stats_cartons_stats()
        RETURNS trigger AS
      $BODY$
        DECLARE
          old_nett_weight DECIMAL;
        BEGIN

          IF (TG_OP = 'INSERT') THEN
            EXECUTE 'UPDATE production_run_stats set cartons_verified = (cartons_verified + 1), cartons_verified_weight = (cartons_verified_weight + COALESCE($2, 0))
                     WHERE production_run_id = $1'
            USING NEW.production_run_id, NEW.nett_weight;
          ELSIF (TG_OP = 'UPDATE') THEN
            IF (OLD.nett_weight IS NULL AND NEW.nett_weight IS NOT NULL) OR (NEW.nett_weight <> OLD.nett_weight) THEN
              IF (OLD.nett_weight IS NULL) THEN  
                old_nett_weight = 0; 
              ELSE
                old_nett_weight = OLD.nett_weight; 
              END IF;
              IF (NEW.nett_weight > old_nett_weight) THEN
                EXECUTE 'UPDATE production_run_stats set cartons_verified_weight = (cartons_verified_weight + $2)
                         WHERE production_run_id = $1'
                USING NEW.production_run_id, NEW.nett_weight - old_nett_weight;
              ELSIF (NEW.nett_weight < old_nett_weight) THEN
                EXECUTE 'UPDATE production_run_stats set cartons_verified_weight = (cartons_verified_weight - $2)
                         WHERE production_run_id = $1'
                USING NEW.production_run_id, old_nett_weight - NEW.nett_weight;
              END IF;
            END IF;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.update_prod_run_stats_cartons_stats()
        OWNER TO postgres;

      CREATE TRIGGER cartons_prod_run_stats_bins_trigger_updates
      AFTER INSERT
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE public.update_prod_run_stats_cartons_stats();

      CREATE TRIGGER prod_run_stats_cartons_update_nett_weight
      AFTER UPDATE OF nett_weight 
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE update_prod_run_stats_cartons_stats();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER cartons_prod_run_stats_bins_trigger_updates ON public.cartons;
      DROP TRIGGER prod_run_stats_cartons_update_nett_weight ON public.cartons;
      DROP FUNCTION public.update_prod_run_stats_cartons_stats();
    SQL
  end
end
