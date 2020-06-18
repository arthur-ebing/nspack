require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION rmt_bin_label_set_received_at()
        RETURNS trigger AS
      $BODY$
      DECLARE
          rmt_bin_label_id INT;
      BEGIN
        IF (NEW.bin_asset_number IS NOT NULL)  THEN
          rmt_bin_label_id := (SELECT id FROM public.rmt_bin_labels where bin_asset_number=NEW.bin_asset_number AND bin_received_at is null order by id desc limit 1);
          EXECUTE 'UPDATE rmt_bin_labels set bin_received_at = now()
                   WHERE id = $1'
          USING rmt_bin_label_id;
        END IF;
        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql;
  
      CREATE TRIGGER set_received_at
      AFTER INSERT ON rmt_bins FOR EACH ROW
      EXECUTE PROCEDURE rmt_bin_label_set_received_at();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER set_received_at ON rmt_bins;
      DROP FUNCTION rmt_bin_label_set_received_at();
    SQL
  end
end
