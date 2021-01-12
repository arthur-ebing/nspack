Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      # Group Login from NSpack
      # -------------------
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_group_login_to_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_module text;
          p_industry_no text;
          p_date text;
          p_time text;
          p_group_code text;
          p_old_code text;
          p_grp_id integer;
        BEGIN
          IF (NEW.from_external_system <> true AND NEW.active) THEN -- ONLY handle group login, logout ignored - handled by script
            SELECT system_resource_code FROM system_resources WHERE id = NEW.system_resource_id INTO p_module;
            IF (p_module IS NULL) THEN
                RAISE EXCEPTION 'Cannot copy group login to MesScada. System resource %s not found', NEW.system_resource_id::text;
            END IF;

            SELECT to_char(current_timestamp, 'YYYY-MM-DD') INTO p_date;
            SELECT to_char(current_timestamp, 'YYYY-MM-DD-HH24:MI:SS') INTO p_time;

            SELECT concat(p_module, '-A-', p_time) INTO p_group_code;

            SELECT id, group_id FROM kromco_legacy.messcada_group_data
            WHERE group_id LIKE concat(p_module, '-A-', '%') INTO p_grp_id, p_old_code;

            IF (p_grp_id IS NOT NULL) THEN
              UPDATE kromco_legacy.messcada_group_data
              SET group_id = p_group_code,
                  group_date = p_date,
                  from_external_system = true
              WHERE id = p_grp_id;
            ELSE
              INSERT INTO kromco_legacy.messcada_group_data(reader_id, module_name, group_id, group_date, from_external_system)
              VALUES('1', p_module, p_group_code, p_date, true);
            END IF;

            INSERT INTO kromco_legacy.messcada_people_group_members(
              reader_id, rfid, industry_number, group_id, group_date, module_name, module_name_alias, last_name, first_name, title, from_external_system)
              SELECT '1', p.identifier, c.personnel_number, p_group_code, p_date, p_module, p_module, c.surname, c.first_name, c.title, true
            FROM (SELECT unnest(NEW.contract_worker_ids) id ) t
            JOIN contract_workers c ON c.id = t.id 
            JOIN personnel_identifiers p ON p.id = c.personnel_identifier_id;

            UPDATE kromco_legacy.people
            SET 
              is_logged_on = 'True' ,
              logged_onto_module = p_module,
              reader_id = '1',
              logged_onoff_time = current_timestamp, 
              updated_at = current_timestamp,
              from_external_system = true
            WHERE industry_number IN (SELECT industry_number FROM contract_workers WHERE id = ANY(NEW.contract_worker_ids));

            UPDATE kromco_legacy.people
            SET	is_logged_on = 'False', 
                logged_onto_module = NULL,
                reader_id = NULL,
                logged_onoff_time = current_timestamp, 
                updated_at = current_timestamp,
                from_external_system = true
            WHERE logged_onto_module = p_module
              AND industry_number NOT IN (SELECT industry_number FROM contract_workers WHERE id = ANY(NEW.contract_worker_ids));
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_group_login_to_messcada
        AFTER INSERT OR UPDATE ON group_incentives
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_group_login_to_messcada();
      SQL

      # Group login from MesScada
      # -------------------
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_group_data_from_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_system_resource_id integer;
        BEGIN
          IF (NEW.from_external_system <> true) THEN

            SELECT id FROM public.system_resources WHERE system_resource_code = NEW.module_name INTO p_system_resource_id;

            UPDATE public.group_incentives SET active = false WHERE system_resource_id = p_system_resource_id AND active;

            INSERT INTO public.group_incentives(system_resource_id, contract_worker_ids, active, from_external_system) VALUES (p_system_resource_id, '{}', true, true);
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_group_data_from_messcada
        AFTER INSERT OR UPDATE ON kromco_legacy.messcada_group_data
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_group_data_from_messcada();

      SQL

      # Group login member from MesScada
      # -------------------
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_group_member_from_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_system_resource_id integer;
          p_contract_worker_id integer;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            SELECT id FROM public.system_resources WHERE system_resource_code = NEW.module_name INTO p_system_resource_id;

            SELECT id FROM public.contract_workers WHERE first_name = NEW.first_name AND surname = NEW.last_name INTO p_contract_worker_id;

            UPDATE public.group_incentives
            SET contract_worker_ids = contract_worker_ids || p_contract_worker_id
            WHERE system_resource_id = p_system_resource_id
              AND active;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_group_member_from_messcada
        AFTER INSERT ON kromco_legacy.messcada_people_group_members
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_group_member_from_messcada();
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      run <<~SQL
        DROP TRIGGER sync_group_login_to_messcada ON public.group_incentives;
        DROP FUNCTION kromco_legacy.sync_group_login_to_messcada();

        DROP TRIGGER sync_group_member_from_messcada ON kromco_legacy.messcada_people_group_members;
        DROP FUNCTION kromco_legacy.sync_group_member_from_messcada();

        DROP TRIGGER sync_group_data_from_messcada ON kromco_legacy.messcada_group_data;
        DROP FUNCTION kromco_legacy.sync_group_data_from_messcada();
      SQL
    end
  end
end
