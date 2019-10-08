-- FUNCTION: public.update_prod_run_stats_bins_tipped()

-- DROP FUNCTION public.update_prod_run_stats_bins_tipped();

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
