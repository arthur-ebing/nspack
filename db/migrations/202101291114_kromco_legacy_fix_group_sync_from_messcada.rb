Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      # Group login member from MesScada
      # -------------------
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_group_member_from_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_system_resource_id integer;
          p_contract_worker_id integer;
          p_target bool;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            SELECT id FROM public.system_resources WHERE system_resource_code = NEW.module_name INTO p_system_resource_id;

            SELECT w.id, p.part_of_group_incentive_target
            FROM public.contract_workers w
            JOIN public.contract_worker_packer_roles p ON p.id = w.packer_role_id
            WHERE w.first_name = NEW.first_name AND w.surname = NEW.last_name
            INTO p_contract_worker_id, p_target;

            IF (p_target) THEN
              UPDATE public.group_incentives
              SET contract_worker_ids = contract_worker_ids || p_contract_worker_id,
                  incentive_target_worker_ids = incentive_target_worker_ids || p_contract_worker_id,
                  from_external_system = true
              WHERE system_resource_id = p_system_resource_id
                AND active;
            ELSE
              UPDATE public.group_incentives
              SET contract_worker_ids = contract_worker_ids || p_contract_worker_id,
                  incentive_non_target_worker_ids = incentive_non_target_worker_ids || p_contract_worker_id,
                  from_external_system = true
              WHERE system_resource_id = p_system_resource_id
                AND active;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      SQL

      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_group_data_from_messcada()
            RETURNS trigger
            LANGUAGE 'plpgsql'
            COST 100
            VOLATILE NOT LEAKPROOF
        AS $BODY$
        DECLARE
          p_system_resource_id integer;
        BEGIN
          IF (NEW.from_external_system <> true) THEN

            SELECT id FROM public.system_resources WHERE system_resource_code = NEW.module_name INTO p_system_resource_id;

            UPDATE public.group_incentives SET active = false, from_external_system = true WHERE system_resource_id = p_system_resource_id AND active;

            IF (NEW.group_id IS NOT NULL) THEN
              INSERT INTO public.group_incentives(system_resource_id, contract_worker_ids, active, from_external_system) VALUES (p_system_resource_id, '{}', true, true);
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$;
      SQL

      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_from_messcada_individual_login()
            RETURNS trigger
            LANGUAGE 'plpgsql'
            COST 100
            VOLATILE NOT LEAKPROOF
        AS $BODY$
        DECLARE
          p_reader_id text;
          p_system_resource_id int;
          p_contract_worker_id int;
          p_packer_role_id int;
          p_group_mode bool;
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
              IF (NEW.is_logged_on = true) THEN
                SELECT id, group_incentive
                  FROM public.system_resources
                  WHERE system_resource_code = NEW.logged_onto_module
                INTO p_system_resource_id, p_group_mode;
                p_reader_id = NEW.reader_id;

                IF (NOT p_group_mode) THEN
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
                END IF;
              ELSE
                SELECT id FROM public.contract_workers WHERE first_name = OLD.first_name AND surname = OLD.last_name INTO p_contract_worker_id;

                UPDATE public.system_resource_logins
                  SET active = false,
                      last_logout_at = current_timestamp,
                      from_external_system = true
                  WHERE contract_worker_id = p_contract_worker_id
                    AND active;
              END IF;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$;
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_group_member_from_messcada()
        RETURNS trigger AS
        $BODY$
        DECLARE
          p_system_resource_id integer;
          p_contract_worker_id integer;
          p_target bool;
        BEGIN
          IF (NEW.from_external_system <> true) THEN
            SELECT id FROM public.system_resources WHERE system_resource_code = NEW.module_name INTO p_system_resource_id;

            SELECT w.id, p.part_of_group_incentive_target
            FROM public.contract_workers w
            JOIN public.contract_worker_packer_roles p ON p.id = w.packer_role_id
            WHERE w.first_name = NEW.first_name AND w.surname = NEW.last_name
            INTO p_contract_worker_id, p_target;

            IF (p_target) THEN
              UPDATE public.group_incentives
              SET contract_worker_ids = contract_worker_ids || p_contract_worker_id,
                  incentive_target_worker_ids = incentive_target_worker_ids || p_contract_worker_id
              WHERE system_resource_id = p_system_resource_id
                AND active;
            ELSE
              UPDATE public.group_incentives
              SET contract_worker_ids = contract_worker_ids || p_contract_worker_id,
                  incentive_non_target_worker_ids = incentive_non_target_worker_ids || p_contract_worker_id
              WHERE system_resource_id = p_system_resource_id
                AND active;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      SQL

      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_group_data_from_messcada()
            RETURNS trigger
            LANGUAGE 'plpgsql'
            COST 100
            VOLATILE NOT LEAKPROOF
        AS $BODY$
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
        $BODY$;
      SQL

      run <<~SQL
        CREATE OR REPLACE FUNCTION kromco_legacy.sync_from_messcada_individual_login()
            RETURNS trigger
            LANGUAGE 'plpgsql'
            COST 100
            VOLATILE NOT LEAKPROOF
        AS $BODY$
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
        $BODY$;
      SQL
    end
  end
end
