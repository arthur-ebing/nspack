Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      # INSERT contract workers
      # ----------------------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_contract_worker_to_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_type_id int;
          p_party_id int;
          p_role_name text;
        BEGIN

          p_type_id = (SELECT id FROM kromco_legacy.party_types WHERE party_type_name = 'PERSON');
          p_role_name = (SELECT packer_role FROM public.contract_worker_packer_roles WHERE id = NEW.packer_role_id);


          INSERT INTO kromco_legacy.parties (party_type_id, party_name, party_type_name)
                       VALUES (p_type_id, NEW.first_name || '_' || NEW.surname, 'PERSON') RETURNING id INTO p_party_id;

          INSERT INTO kromco_legacy.people(party_id, first_name, last_name, title, industry_number, default_role, selected_role, from_external_system)
          VALUES (p_party_id, NEW.first_name, NEW.surname, NEW.title, NEW.personnel_number, p_role_name, p_role_name, true);

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      SQL

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

      # Login from MesScada
      # -------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_from_messcada_individual_login()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_reader_id text;
          p_system_resource_id int;
          p_contract_worker_id int;
          p_packer_role_id int;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            p_packer_role_id = (SELECT id FROM contract_worker_packer_roles WHERE packer_role = NEW.selected_role);
            SELECT id FROM public.contract_workers WHERE first_name = NEW.first_name AND surname = NEW.last_name INTO p_contract_worker_id;

            IF (NEW.selected_role <> OLD.selected_role) THEN
              UPDATE public.contract_workers
                SET packer_role_id = p_packer_role_id,
                    from_external_system = true
                WHERE id = p_contract_worker_id;
            END IF;

            IF (NEW.is_logged_on <> OLD.is_logged_on) THEN
              IF (NEW.is_logged_on = 'True') THEN
                SELECT id FROM public.system_resources WHERE system_resource_code = NEW.logged_onto_module INTO p_system_resource_id;
                p_reader_id = NEW.reader_id;

                IF (EXISTS(SELECT id FROM public.system_resource_logins WHERE system_resource_id = p_system_resource_id AND card_reader = p_reader_id)) THEN
                  UPDATE public.system_resource_logins
                    SET contract_worker_id = p_contract_worker_id,
                        identifier = NEW.industry_number,
                        login_at = current_timestamp,
                        active = true,
                        from_external_system = true
                  WHERE system_resource_id = p_system_resource_id
                    AND card_reader = p_reader_id;
                ELSE
                  INSERT INTO public.system_resource_logins(
                    system_resource_id, card_reader, contract_worker_id, identifier, login_at, active, from_external_system)
                    VALUES (p_system_resource_id, p_reader_id, p_contract_worker_id, NEW.industry_number, current_timestamp, true, true);
                END IF;
              ELSE
                SELECT id FROM public.contract_workers WHERE first_name = OLD.first_name AND surname = OLD.last_name INTO p_contract_worker_id;

                UPDATE public.system_resource_logins
                  SET active = false,
                      last_logout_at = current_timestamp,
                      from_external_system = true
                  WHERE contract_worker_id = p_contract_worker_id;
              END IF;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        DROP TRIGGER sync_from_messcada_individual_login ON kromco_legacy.people;

        CREATE TRIGGER sync_from_messcada_individual_login
        AFTER UPDATE ON kromco_legacy.people
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_from_messcada_individual_login();
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      # INSERT contract workers
      # ----------------------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_contract_worker_to_messcada()
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
      SQL

      # UPDATE contract workers
      # ----------------------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.update_contract_worker_on_messcada()
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
      SQL

      # Login from MesScada
      # -------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_from_messcada_individual_login()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_reader_id text;
          p_system_resource_id int;
          p_contract_worker_id int;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            IF (NEW.is_logged_on = 'True') THEN
              SELECT id FROM public.system_resources WHERE system_resource_code = NEW.logged_onto_module INTO p_system_resource_id;
              p_reader_id = NEW.reader_id;
              SELECT id FROM public.contract_workers WHERE first_name = NEW.first_name AND surname = NEW.last_name INTO p_contract_worker_id;

              IF (EXISTS(SELECT id FROM public.system_resource_logins WHERE system_resource_id = p_system_resource_id AND card_reader = p_reader_id)) THEN
                UPDATE public.system_resource_logins
                  SET contract_worker_id = p_contract_worker_id,
                      identifier = NEW.industry_number,
                      login_at = current_timestamp,
                      active = true,
                      from_external_system = true
                WHERE system_resource_id = p_system_resource_id
                  AND card_reader = p_reader_id;
              ELSE
                INSERT INTO public.system_resource_logins(
                  system_resource_id, card_reader, contract_worker_id, identifier, login_at, active, from_external_system)
                  VALUES (p_system_resource_id, p_reader_id, p_contract_worker_id, NEW.industry_number, current_timestamp, true, true);
              END IF;
            ELSE
              SELECT id FROM public.contract_workers WHERE first_name = OLD.first_name AND surname = OLD.last_name INTO p_contract_worker_id;

              UPDATE public.system_resource_logins
                SET active = false,
                    last_logout_at = current_timestamp,
                    from_external_system = true
                WHERE contract_worker_id = p_contract_worker_id;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        DROP TRIGGER sync_from_messcada_individual_login ON kromco_legacy.people;

        CREATE TRIGGER sync_from_messcada_individual_login
        AFTER INSERT OR UPDATE ON kromco_legacy.people
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_from_messcada_individual_login();
      SQL
    end
  end
end
