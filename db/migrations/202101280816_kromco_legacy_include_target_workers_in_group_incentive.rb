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
      SQL
    end
  end
end
