Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      run <<~SQL
        CREATE FUNCTION kromco_legacy.sync_contract_worker_packer_role_to_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          INSERT INTO kromco_legacy.messcada_people_roles (code, description, created_at, updated_at)
                       VALUES (NEW.packer_role, NEW.packer_role, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER sync_contract_worker_packer_role_to_messcada
        AFTER INSERT ON contract_worker_packer_roles
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.sync_contract_worker_packer_role_to_messcada();
      SQL

      run <<~SQL
        CREATE FUNCTION kromco_legacy.update_contract_worker_packer_role_on_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          UPDATE kromco_legacy.messcada_people_roles
            SET code = NEW.packer_role,
                description = NEW.packer_role,
                updated_at = CURRENT_TIMESTAMP
          WHERE code = OLD.packer_role;

          RETURN NEW;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER update_contract_worker_packer_role_on_messcada
        AFTER UPDATE ON contract_worker_packer_roles
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.update_contract_worker_packer_role_on_messcada();
      SQL

      run <<~SQL
        CREATE FUNCTION kromco_legacy.delete_contract_worker_packer_role_from_messcada()
        RETURNS trigger AS
        $BODY$
        BEGIN
          DELETE FROM kromco_legacy.messcada_people_roles WHERE code = OLD.packer_role;

          RETURN OLD;
        END;
        $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;

        CREATE TRIGGER delete_contract_worker_packer_role_from_messcada
        AFTER DELETE ON contract_worker_packer_roles
        FOR EACH ROW
        EXECUTE PROCEDURE kromco_legacy.delete_contract_worker_packer_role_from_messcada();
      SQL
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      run <<~SQL
        DROP TRIGGER sync_contract_worker_packer_role_to_messcada ON public.contract_worker_packer_roles;
        DROP FUNCTION kromco_legacy.sync_contract_worker_packer_role_to_messcada();

        DROP TRIGGER update_contract_worker_packer_role_on_messcada ON public.contract_worker_packer_roles;
        DROP FUNCTION kromco_legacy.update_contract_worker_packer_role_on_messcada();

        DROP TRIGGER delete_contract_worker_packer_role_from_messcada ON contract_worker_packer_roles;
        DROP FUNCTION kromco_legacy.delete_contract_worker_packer_role_from_messcada();
      SQL
    end
  end
end
