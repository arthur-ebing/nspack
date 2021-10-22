Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      # UPDATE contract workers
      # ----------------------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.update_contract_worker_on_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_role_name text;
          p_person_id int;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            IF (OLD.first_name <> NEW.first_name OR OLD.surname <> NEW.surname) THEN
              UPDATE kromco_legacy.parties
              SET party_name = NEW.first_name || '_' || NEW.surname
              WHERE party_name = OLD.first_name || '_' || OLD.surname;
            END IF;

            p_role_name = (SELECT packer_role FROM public.contract_worker_packer_roles WHERE id = NEW.packer_role_id);
            p_person_id = (SELECT id FROM kromco_legacy.people WHERE first_name = OLD.first_name AND last_name = OLD.surname);

            UPDATE kromco_legacy.people
              SET first_name = NEW.first_name,
              last_name = NEW.surname,
              title = NEW.title,
              selected_role = p_role_name,
              industry_number = NEW.personnel_number,
              from_external_system = true
            WHERE first_name = OLD.first_name
              AND last_name = OLD.surname;  

            IF (OLD.personnel_number <> NEW.personnel_number) THEN
              UPDATE kromco_legacy.messcada_people_view_messcada_rfid_allocations
              SET industry_number = NEW.personnel_number
              WHERE person_id = p_person_id;

              UPDATE kromco_legacy.messcada_people_group_members
              SET first_name = NEW.first_name,
              last_name = NEW.surname,
              title = NEW.title,
              industry_number = NEW.personnel_number,
              from_external_system = true
              WHERE first_name = OLD.first_name
                AND last_name = OLD.surname;  
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      # UPDATE contract workers
      # ----------------------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.update_contract_worker_on_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_role_name text;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            IF (OLD.first_name <> NEW.first_name OR OLD.surname <> NEW.surname) THEN
              UPDATE kromco_legacy.parties
              SET party_name = NEW.first_name || '_' || NEW.surname
              WHERE party_name = OLD.first_name || '_' || OLD.surname;
            END IF;

            p_role_name = (SELECT packer_role FROM public.contract_worker_packer_roles WHERE id = NEW.packer_role_id);

            UPDATE kromco_legacy.people
              SET first_name = NEW.first_name,
              last_name = NEW.surname,
              title = NEW.title,
              selected_role = p_role_name,
              industry_number = NEW.personnel_number,
              from_external_system = true
            WHERE first_name = OLD.first_name
              AND last_name = OLD.surname;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      SQL
    end
  end
end
