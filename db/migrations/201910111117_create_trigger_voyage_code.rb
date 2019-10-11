require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION voyages_set_voyage_code()
        RETURNS trigger AS
      $BODY$
      DECLARE
          vessel_seq text;
          vessel_name text;
      BEGIN
        vessel_seq := (SELECT (COUNT(*) + 1)  FROM voyages WHERE vessel_id = NEW."vessel_id" AND year = NEW."year");
        vessel_name := (SELECT vessel_code FROM vessels WHERE id = NEW."vessel_id");
        NEW."voyage_code" := NEW."year" || '_' || vessel_seq || '_' || vessel_name || '_' || NEW."voyage_number";
        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql;
  
      CREATE TRIGGER set_voyage_code
      BEFORE INSERT ON voyages FOR EACH ROW
      EXECUTE PROCEDURE voyages_set_voyage_code();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER set_voyage_code ON voyages;
      DROP FUNCTION voyages_set_voyage_code();
    SQL
  end
end
