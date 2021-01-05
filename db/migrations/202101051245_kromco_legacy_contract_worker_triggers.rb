Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_contract_worker_to_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_type_id int;
          p_party_id int;
        BEGIN

          p_type_id = (SELECT id FROM kromco_legacy.party_types WHERE party_type_name = 'PERSON');


          INSERT INTO kromco_legacy.parties (party_type_id, party_name, party_type_name)
                       VALUES (p_type_id, NEW.first_name || '_' || NEW.surname, 'PERSON') RETURNING id INTO p_party_id;

          INSERT INTO kromco_legacy.people(party_id, first_name, last_name, title, industry_number)
          VALUES (p_party_id, NEW.first_name, NEW.surname, NEW.title, NEW.personnel_number);

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_worker_to_messcada
        AFTER INSERT ON contract_workers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_contract_worker_to_messcada();
      SQL

      run <<~SQL
        CREATE FUNCTION kromco_legacy.update_contract_worker_on_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          IF (OLD.first_name <> NEW.first_name OR OLD.surname <> NEW.surname) THEN
            UPDATE kromco_legacy.parties
            SET party_name = NEW.first_name || '_' || NEW.surname
            WHERE party_name = OLD.first_name || '_' || OLD.surname;
          END IF;

          UPDATE kromco_legacy.people
            SET first_name = NEW.first_name,
            last_name = NEW.surname,
            title = NEW.title,
            industry_number = NEW.personnel_number
          WHERE first_name = OLD.first_name
            AND last_name = OLD.surname;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER update_worker_on_messcada
        AFTER UPDATE ON contract_workers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.update_contract_worker_on_messcada();
      SQL

      run <<~SQL
        CREATE FUNCTION kromco_legacy.delete_contract_worker_from_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          DELETE FROM kromco_legacy.people
          WHERE first_name = OLD.first_name
            AND last_name = OLD.surname;

          DELETE FROM kromco_legacy.parties WHERE party_name = OLD.first_name || '_' || OLD.surname;

          RETURN OLD;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER delete_worker_from_messcada
        AFTER DELETE ON contract_workers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.delete_contract_worker_from_messcada();
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      run <<~SQL
        DROP TRIGGER sync_worker_to_messcada ON public.contract_workers;
        DROP FUNCTION kromco_legacy.sync_contract_worker_to_messcada();

        DROP TRIGGER update_worker_on_messcada ON public.contract_workers;
        DROP FUNCTION kromco_legacy.update_contract_worker_on_messcada();

        DROP TRIGGER delete_worker_from_messcada ON contract_workers;
        DROP FUNCTION kromco_legacy.delete_contract_worker_from_messcada();
      SQL
    end
  end
end
