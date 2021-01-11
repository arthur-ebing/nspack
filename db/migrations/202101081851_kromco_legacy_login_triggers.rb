Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_individual_login_to_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_module text;
          p_industry_no text;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
              SELECT system_resource_code FROM system_resources WHERE id = NEW.system_resource_id INTO p_module;
              IF (p_module IS NULL) THEN
                  RAISE EXCEPTION 'Cannot copy login to MesScada. System resource %s not found', NEW.system_resource_id::text;
              END IF;

              SELECT personnel_number FROM contract_workers WHERE id = NEW.contract_worker_id INTO p_industry_no;
              IF (p_industry_no IS NULL) THEN
                  RAISE EXCEPTION 'Cannot copy login to MesScada. Contract worker %s not found', NEW.contract_worker_id::text;
              END IF;

            IF (NEW.active) THEN
              UPDATE kromco_legacy.people
              SET 
                is_logged_on = 'True' ,
                logged_onto_module = p_module,
                reader_id = NEW.card_reader,
                logged_onoff_time = current_timestamp, 
                updated_at = current_timestamp,
                from_external_system = true
              WHERE industry_number = p_industry_no;
              -- should raise if people record not found...
            ELSE
              UPDATE kromco_legacy.people
              SET	is_logged_on = 'False', 
                  logged_onto_module = NULL,
                  reader_id = NULL,
                  logged_onoff_time = current_timestamp, 
                  updated_at = current_timestamp,
                  from_external_system = true
              WHERE industry_number = p_industry_no;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_individual_login_to_messcada
        AFTER INSERT OR UPDATE ON system_resource_logins
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_individual_login_to_messcada();
      SQL

      # Login from MesScada
      # -------------------
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_from_messcada_individual_login()
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

        CREATE TRIGGER sync_from_messcada_individual_login
        AFTER INSERT OR UPDATE ON kromco_legacy.people
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_from_messcada_individual_login();
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      run <<~SQL
        DROP TRIGGER sync_individual_login_to_messcada ON public.system_resource_logins;
        DROP FUNCTION kromco_legacy.sync_individual_login_to_messcada();

        DROP TRIGGER sync_from_messcada_individual_login ON kromco_legacy.people;
        DROP FUNCTION kromco_legacy.sync_from_messcada_individual_login();
      SQL
    end
  end
end
