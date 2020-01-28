Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_bin_check_if_delivery_tipped()
        RETURNS trigger AS
      $BODY$
        DECLARE
          tip_count INTEGER;
        BEGIN
          IF (NEW.bin_tipped) THEN
            EXECUTE 'SELECT COUNT(*) FROM rmt_bins WHERE rmt_delivery_id = $1 AND NOT bin_tipped AND id <> $2;' INTO tip_count USING NEW.rmt_delivery_id, NEW.id;

            IF (tip_count = 0) THEN
              EXECUTE 'UPDATE rmt_deliveries SET delivery_tipped = true, tipping_complete_date_time = current_timestamp WHERE id = $1;' USING NEW.rmt_delivery_id;
            END IF;
          END IF;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_bin_check_if_delivery_tipped()
        OWNER TO postgres;

      CREATE TRIGGER rmt_bins_check_if_delivery_tipped
        AFTER UPDATE OF bin_tipped
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_bin_check_if_delivery_tipped();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER rmt_bins_check_if_delivery_tipped ON public.rmt_bins;

      DROP FUNCTION public.fn_bin_check_if_delivery_tipped();
    SQL
  end
end
