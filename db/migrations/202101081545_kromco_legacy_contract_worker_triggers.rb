Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      # INSERT contract workers
      # ----------------------------------
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

      # UPDATE contract workers
      # ----------------------------------
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

      # LINK contract worker to personnel_identifier
      # -----------------------------------------------
      run <<~SQL
        CREATE FUNCTION kromco_legacy.link_contract_worker_on_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_rfid text;
          p_person_id int;
        BEGIN
          IF (OLD.personnel_identifier_id IS NOT NULL) THEN
            -- delete old rfid link
            DELETE FROM kromco_legacy.messcada_people_view_messcada_rfid_allocations
            WHERE industry_number = OLD.personnel_number;
          END IF;

          IF (NEW.personnel_identifier_id IS NOT NULL) THEN
            p_rfid = (SELECT identifier FROM personnel_identifiers WHERE id = NEW.personnel_identifier_id);

            p_person_id = (SELECT id FROM kromco_legacy.people WHERE first_name = OLD.first_name AND last_name = OLD.surname);

            -- add new rfid link
            INSERT INTO kromco_legacy.messcada_people_view_messcada_rfid_allocations(industry_number, rfid, person_id, created_at, updated_at)
              VALUES (NEW.personnel_number, p_rfid, p_person_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER link_worker_on_messcada
        AFTER UPDATE OF personnel_identifier_id ON contract_workers
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.link_contract_worker_on_messcada();
      SQL

      # DELETE contract workers
      # ----------------------------------
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

        DROP TRIGGER link_worker_on_messcada ON public.contract_workers;
        DROP FUNCTION kromco_legacy.link_contract_worker_on_messcada();

        DROP TRIGGER update_worker_on_messcada ON public.contract_workers;
        DROP FUNCTION kromco_legacy.update_contract_worker_on_messcada();

        DROP TRIGGER delete_worker_from_messcada ON contract_workers;
        DROP FUNCTION kromco_legacy.delete_contract_worker_from_messcada();
      SQL
    end
  end
end
