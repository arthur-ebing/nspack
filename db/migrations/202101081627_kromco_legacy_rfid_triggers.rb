Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_personnel_identifier_to_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          INSERT INTO kromco_legacy.messcada_rfid_allocations (rfid, created_at, created_by)
                       VALUES (NEW.identifier, CURRENT_TIMESTAMP, 'nspack');

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_personnel_identifier_to_messcada
        AFTER INSERT ON personnel_identifiers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_personnel_identifier_to_messcada();
      SQL

      run <<~SQL
        CREATE FUNCTION kromco_legacy.update_personnel_identifier_on_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          UPDATE kromco_legacy.messcada_rfid_allocations
            SET rfid = NEW.identifier,
                updated_at = CURRENT_TIMESTAMP
          WHERE rfid = OLD.identifier;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER update_personnel_identifier_on_messcada
        AFTER UPDATE ON personnel_identifiers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.update_personnel_identifier_on_messcada();
      SQL

      run <<~SQL
        CREATE FUNCTION kromco_legacy.delete_personnel_identifier_from_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          DELETE FROM kromco_legacy.messcada_people_view_messcada_rfid_allocations WHERE rfid = OLD.identifier;
          DELETE FROM kromco_legacy.messcada_rfid_allocations WHERE rfid = OLD.identifier;

          RETURN OLD;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER delete_personnel_identifier_from_messcada
        AFTER DELETE ON personnel_identifiers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.delete_personnel_identifier_from_messcada();
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      run <<~SQL
        DROP TRIGGER sync_personnel_identifier_to_messcada ON public.personnel_identifiers;
        DROP FUNCTION kromco_legacy.sync_personnel_identifier_to_messcada();

        DROP TRIGGER update_personnel_identifier_on_messcada ON public.personnel_identifiers;
        DROP FUNCTION kromco_legacy.update_personnel_identifier_on_messcada();

        DROP TRIGGER delete_personnel_identifier_from_messcada ON personnel_identifiers;
        DROP FUNCTION kromco_legacy.delete_personnel_identifier_from_messcada();
      SQL
    end
  end
end
