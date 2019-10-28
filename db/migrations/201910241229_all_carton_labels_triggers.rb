Sequel.migration do
  up do
    # Function and triggers to update production_run_stats carton_labels_printed
    # on carton_labels insert

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.update_prod_run_stats_carton_labels_printed()
        RETURNS trigger AS
      $BODY$
        DECLARE
        BEGIN
          IF (TG_OP = 'INSERT') THEN
            EXECUTE 'UPDATE production_run_stats set carton_labels_printed = carton_labels_printed + 1
                     WHERE production_run_id = $1'
            USING NEW.production_run_id;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.update_prod_run_stats_carton_labels_printed()
        OWNER TO postgres;

      CREATE TRIGGER carton_labels_prod_run_stats_trigger_updates
      AFTER INSERT
      ON public.carton_labels
      FOR EACH ROW
      EXECUTE PROCEDURE public.update_prod_run_stats_carton_labels_printed();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER carton_labels_prod_run_stats_trigger_updates ON public.carton_labels;
      DROP FUNCTION public.update_prod_run_stats_carton_labels_printed();
    SQL
  end
end
