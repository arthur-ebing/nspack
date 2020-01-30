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

              -- Log status:
              EXECUTE 'INSERT INTO "audit"."current_statuses" ("user_name", "table_name", "row_data_id", "status")
                VALUES (''System'', ''rmt_deliveries'', $1, ''DELIVERY TIPPED'')
                ON CONFLICT ("table_name", "row_data_id") DO UPDATE SET "user_name" = "excluded"."user_name", "row_data_id" = "excluded"."row_data_id",
                 "status" = "excluded"."status", "comment" = "excluded"."comment", "transaction_id" = txid_current(), "action_tstamp_tx" = current_timestamp;'
                 USING NEW.rmt_delivery_id;

              EXECUTE 'INSERT INTO "audit"."status_logs" ("user_name", "table_name", "row_data_id", "status")
               VALUES (''System'', ''rmt_deliveries'', $1, ''DELIVERY TIPPED'');'
               USING NEW.rmt_delivery_id;
            END IF;
          END IF;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_bin_check_if_delivery_tipped()
        OWNER TO postgres;
    SQL
  end

  down do
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
    SQL
    SQL
  end
end
