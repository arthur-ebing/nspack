CREATE TRIGGER update_prod_run_stats_bins_tipped
AFTER UPDATE OF production_run_tipped_id ON rmt_bins
FOR EACH ROW
EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();	