require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    # Function and triggers to update production_run_stats bins_tipped and bins_tipped_weight
    # on rmt_bins bin_tipped and scrapped update

    run <<~SQL
        DROP TRIGGER update_prod_run_stats_bins_tipped ON rmt_bins;
        DROP FUNCTION public.update_prod_run_stats_bins_tipped();

        CREATE OR REPLACE FUNCTION public.update_prod_run_stats_bins_tipped()
           RETURNS trigger AS
        $BODY$
           DECLARE
           BEGIN

            IF (TG_OP = 'UPDATE') THEN
              IF (NEW.bin_tipped <> OLD.bin_tipped) THEN
                IF (NEW.bin_tipped IS TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped + $2), bins_tipped_weight = (bins_tipped_weight + $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                ELSIF (NEW.bin_tipped IS NOT TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped - $2), bins_tipped_weight = (bins_tipped_weight - $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                END IF;
              END IF;
              
              IF (NEW.scrapped <> OLD.scrapped) THEN
                IF (NEW.scrapped IS TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped - $2), bins_tipped_weight = (bins_tipped_weight - $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                ELSIF (NEW.scrapped IS NOT TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped + $2), bins_tipped_weight = (bins_tipped_weight + $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                END IF;
              END IF;

              IF (OLD.nett_weight IS NULL AND NEW.nett_weight IS NOT NULL) OR (NEW.nett_weight <> OLD.nett_weight) THEN
                IF (NEW.production_run_rebin_id IS NOT NULL) THEN
                  EXECUTE 'UPDATE production_run_stats set rebins_weight = (rebins_weight + $2)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_rebin_id, NEW.nett_weight - OLD.nett_weight;
                END IF;
              END IF;
            ELSIF (TG_OP = 'INSERT') THEN
              EXECUTE 'UPDATE production_run_stats set rebins_created = (rebins_created + $2), rebins_weight = (rebins_weight + $3)
                       WHERE production_run_id = $1'
              USING NEW.production_run_rebin_id, NEW.qty_bins, NEW.nett_weight;
            END IF;

          RETURN NEW;

        END

        $BODY$
          LANGUAGE plpgsql VOLATILE
          COST 100;
        ALTER FUNCTION public.update_prod_run_stats_bins_tipped()
          OWNER TO postgres;

        CREATE TRIGGER prod_run_stats_bins_update_bin_tipped
        AFTER UPDATE OF bin_tipped 
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();

        CREATE TRIGGER prod_run_stats_bins_update_scrapped
        AFTER UPDATE OF scrapped 
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();

        CREATE TRIGGER prod_run_stats_bins_update_nett_weight
        BEFORE UPDATE OF nett_weight 
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();

        CREATE TRIGGER rmt_bins_prod_run_stats_bins_trigger_updates
        BEFORE INSERT
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE public.update_prod_run_stats_bins_tipped();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER prod_run_stats_bins_update_bin_tipped ON rmt_bins;
      DROP TRIGGER prod_run_stats_bins_update_scrapped ON rmt_bins;
      DROP TRIGGER prod_run_stats_bins_update_nett_weight ON rmt_bins;
      DROP TRIGGER rmt_bins_prod_run_stats_bins_trigger_updates ON rmt_bins;
      DROP FUNCTION public.update_prod_run_stats_bins_tipped();
      
      CREATE FUNCTION public.update_prod_run_stats_bins_tipped()
            RETURNS trigger
            LANGUAGE 'plpgsql'
            COST 100
            VOLATILE NOT LEAKPROOF
        AS $BODY$BEGIN

            IF (TG_OP = 'UPDATE') THEN
              IF (OLD.production_run_tipped_id IS NULL AND NEW.production_run_tipped_id IS NOT NULL) OR (NEW.production_run_tipped_id <> OLD.production_run_tipped_id) THEN
            UPDATE production_run_stats set bins_tipped=bins_tipped+NEW.qty_bins, bins_tipped_weight=bins_tipped_weight+NEW.nett_weight where (production_run_stats.production_run_id=NEW.production_run_tipped_id);
              END IF;
            END IF;

          RETURN NEW;

        END $BODY$;

        ALTER FUNCTION public.update_prod_run_stats_bins_tipped()
            OWNER TO postgres;


        CREATE TRIGGER update_prod_run_stats_bins_tipped
        AFTER UPDATE OF production_run_tipped_id ON rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();
    SQL
  end
end
