Sequel.migration do
  up do
    run <<~SQL
    -- ==========================================================================
    -- CREATE AND DELETE BIN
    -- ==========================================================================
  
    CREATE OR REPLACE FUNCTION public.fn_add_create_and_delete_rmt_bin_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        bin_event_type TEXT;
      BEGIN
        IF (TG_OP = 'DELETE') THEN              
          IF (OLD.rmt_delivery_id IS NOT NULL) THEN
            bin_event_type = 'BIN_DELETED';
          ELSIF (OLD.production_run_rebin_id IS NOT NULL) THEN
            bin_event_type = 'REBIN_DELETED';
          ELSE
            bin_event_type = 'REBIN_DELETED';
          END IF;
          EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type) VALUES($1, $2);' 
          USING OLD.id, bin_event_type;
          RETURN OLD;
        ELSIF (TG_OP = 'INSERT') THEN
          IF (NEW.rmt_delivery_id IS NOT NULL) THEN
            bin_event_type = 'DELIVERY_RECEIVED';
          ELSIF (NEW.production_run_rebin_id IS NOT NULL) THEN
            bin_event_type = 'REBIN_CREATED';
          ELSE
            bin_event_type = 'REBIN_CREATED';
          END IF;
          EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type) VALUES($1, $2);' 
          USING NEW.id, bin_event_type;
          RETURN NEW;
        ELSE
          RETURN NEW;
        END IF;
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_create_and_delete_rmt_bin_to_queue()
      OWNER TO postgres;
    SQL

    run <<~SQL
    -- ==========================================================================================================================
    -- MONITORS RMT_BINS updates to  farm_id, rmt_material_owner_party_role_id and rmt_container_material_type_id
    -- ==========================================================================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_bin_update_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        changes_made TEXT;
      BEGIN
        
          IF (NEW.production_run_rebin_id IS NOT NULL) THEN
            IF (NEW.rmt_material_owner_party_role_id <> OLD.rmt_material_owner_party_role_id) OR (NEW.rmt_container_material_type_id <> OLD.rmt_container_material_type_id) THEN
              changes_made = '{ before: { rmt_material_owner_party_role_id: ' || OLD.rmt_material_owner_party_role_id || ',
                                          rmt_container_material_type_id: ' || OLD.rmt_container_material_type_id || '}, 
                                after: { rmt_material_owner_party_role_id: ' || NEW.rmt_material_owner_party_role_id || ',
                                         rmt_container_material_type_id: ' || NEW.rmt_container_material_type_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'REBIN_MATERIAL_OWNER_CHANGED', changes_made;
            END IF;
          ELSIF (NEW.rmt_delivery_id IS NOT NULL) THEN
            IF (NEW.farm_id <> OLD.farm_id) THEN
              changes_made = '{ before: { farm_id: ' || OLD.farm_id || '}, after: { farm_id: ' || NEW.farm_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'FARM_CHANGED', changes_made;
            END IF;
            IF (NEW.rmt_material_owner_party_role_id <> OLD.rmt_material_owner_party_role_id) OR (NEW.rmt_container_material_type_id <> OLD.rmt_container_material_type_id) THEN
              changes_made = '{ before: { rmt_material_owner_party_role_id: ' || OLD.rmt_material_owner_party_role_id || ',
                                          rmt_container_material_type_id: ' || OLD.rmt_container_material_type_id || '}, 
                                after: { rmt_material_owner_party_role_id: ' || NEW.rmt_material_owner_party_role_id || ',
                                         rmt_container_material_type_id: ' || NEW.rmt_container_material_type_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'MATERIAL_OWNER_CHANGED', changes_made;
            END IF;
          ELSE
            IF (NEW.rmt_material_owner_party_role_id <> OLD.rmt_material_owner_party_role_id) OR (NEW.rmt_container_material_type_id <> OLD.rmt_container_material_type_id) THEN
              changes_made = '{ before: { rmt_material_owner_party_role_id: ' || OLD.rmt_material_owner_party_role_id || ',
                                          rmt_container_material_type_id: ' || OLD.rmt_container_material_type_id || '}, 
                                after: { rmt_material_owner_party_role_id: ' || NEW.rmt_material_owner_party_role_id || ',
                                         rmt_container_material_type_id: ' || NEW.rmt_container_material_type_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'REBIN_MATERIAL_OWNER_CHANGED', changes_made;
            END IF;
          END IF;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_bin_update_to_queue()
      OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
    -- ==========================================================================
    -- CREATE AND DELETE BIN
    -- ==========================================================================
  
    CREATE OR REPLACE FUNCTION public.fn_add_create_and_delete_rmt_bin_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        bin_event_type TEXT;
      BEGIN
        IF (TG_OP = 'DELETE') THEN
          IF (OLD.rmt_delivery_id IS NOT NULL) THEN
            bin_event_type = 'BIN_DELETED';
          ELSIF (OLD.production_run_rebin_id IS NOT NULL) THEN
            bin_event_type = 'REBIN_DELETED';
          ELSE
            bin_event_type = 'REBIN_DELETED';
          END IF;
          EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type) VALUES($1, $2);' 
          USING OLD.id, bin_event_type;
        ELSIF (TG_OP = 'INSERT') THEN
          IF (NEW.rmt_delivery_id IS NOT NULL) THEN
            bin_event_type = 'DELIVERY_RECEIVED';
          ELSIF (NEW.production_run_rebin_id IS NOT NULL) THEN
            bin_event_type = 'REBIN_CREATED';
          ELSE
            bin_event_type = 'REBIN_CREATED';
          END IF;
          EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type) VALUES($1, $2);' 
          USING NEW.id, bin_event_type;
        END IF;
        RETURN NEW;
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_create_and_delete_rmt_bin_to_queue()
      OWNER TO postgres;
    SQL

    run <<~SQL
    -- ==========================================================================================================================
    -- MONITORS RMT_BINS updates to  farm_id, rmt_material_owner_party_role_id and rmt_container_material_type_id
    -- ==========================================================================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_bin_update_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        changes_made TEXT;
      BEGIN
        
          IF (NEW.production_run_rebin_id IS NOT NULL) THEN
            IF (NEW.rmt_material_owner_party_role_id <> OLD.rmt_material_owner_party_role_id) OR (NEW.rmt_container_material_type_id <> OLD.rmt_container_material_type_id) THEN
              changes_made = '{ before: { rmt_material_owner_party_role_id: ' || OLD.rmt_material_owner_party_role_id || ',
                                          rmt_container_material_type_id: ' || OLD.rmt_container_material_type_id || '}, 
                                after: { rmt_material_owner_party_role_id: ' || NEW.rmt_material_owner_party_role_id || ',
                                         rmt_container_material_type_id: ' || NEW.rmt_container_material_type_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'REBIN_MATERIAL_OWNER_CHANGED', changes_made;
            END IF;
          ELSIF (NEW.rmt_delivery_id IS NOT NULL) THEN
            IF (NEW.farm_id <> OLD.farm_id) THEN
              changes_made = '{ before: { farm_id: ' || OLD.farm_id || '}, after: { farm_id: ' || NEW.farm_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'FARM_CHANGED', changes_made;
            END IF;
            IF (NEW.rmt_material_owner_party_role_id <> OLD.rmt_material_owner_party_role_id) OR (NEW.rmt_container_material_type_id <> OLD.rmt_container_material_type_id) THEN
              changes_made = '{ before: { rmt_material_owner_party_role_id: ' || OLD.rmt_material_owner_party_role_id || ',
                                          rmt_container_material_type_id: ' || OLD.rmt_container_material_type_id || '}, 
                                after: { rmt_material_owner_party_role_id: ' || NEW.rmt_material_owner_party_role_id || ',
                                         rmt_container_material_type_id: ' || NEW.rmt_container_material_type_id || ' } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'MATERIAL_OWNER_CHANGED', changes_made;
            END IF;
          END IF;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_bin_update_to_queue()
      OWNER TO postgres;
    SQL
  end
end
