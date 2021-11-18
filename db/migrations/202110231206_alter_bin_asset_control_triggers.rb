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
    -- ==========================================================================
    -- MONITORS RMT_BINS BIN_TIPPED
    -- ==========================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_bin_tipped_change_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        bin_event_type TEXT;
        changes_made TEXT;
      BEGIN
        
          IF (NEW.bin_tipped) THEN
            changes_made = '{ before: { bin_tipped: false }, after: { bin_tipped: true } }';
            bin_event_type = 'BIN_TIPPED';
          ELSE
            changes_made = '{ before: { bin_tipped: true }, after: { bin_tipped: false } }';
            bin_event_type = 'BIN_UNTIPPED';
          END IF;
          EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
          USING NEW.id, bin_event_type, changes_made;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_bin_tipped_change_to_queue()
      OWNER TO postgres;
    SQL

    run <<~SQL
    -- ==========================================================================
    -- MONITORS RMT_BINS SCRAPPED
    -- ==========================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_bin_scrapped_change_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        bin_event_type TEXT;
        changes_made TEXT;
      BEGIN
        
          IF (OLD.production_run_rebin_id IS NOT NULL) OR (NEW.production_run_rebin_id IS NOT NULL) THEN
            IF (NEW.scrapped) THEN
              changes_made = '{ before: { scrapped: false }, after: { scrapped: true } }';
              bin_event_type = 'REBIN_SCRAPPED';
            ELSE
              changes_made = '{ before: { scrapped: true }, after: { scrapped: false } }';
              bin_event_type = 'REBIN_UNSCRAPPED';
            END IF;
            EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
            USING NEW.id, bin_event_type, changes_made;
          ELSIF (OLD.rmt_delivery_id IS NOT NULL) OR (NEW.rmt_delivery_id IS NOT NULL) THEN
              IF (NEW.scrapped) THEN
                changes_made = '{ before: { scrapped: false }, after: { scrapped: true } }';
                bin_event_type = 'BIN_SCRAPPED';
              ELSE
                changes_made = '{ before: { scrapped: true }, after: { scrapped: false } }';
                bin_event_type = 'BIN_UNSCRAPPED';
              END IF;
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, bin_event_type, changes_made;
          ELSE
              IF (NEW.scrapped) THEN
                changes_made = '{ before: { scrapped: false }, after: { scrapped: true } }';
                bin_event_type = 'REBIN_SCRAPPED';
              ELSE
                changes_made = '{ before: { scrapped: true }, after: { scrapped: false } }';
                bin_event_type = 'REBIN_UNSCRAPPED';
              END IF;
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, bin_event_type, changes_made;
          END IF;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_bin_scrapped_change_to_queue()
      OWNER TO postgres;
    SQL

    run <<~SQL
    -- ==========================================================================
    -- MONITORS RMT_BINS SHIPPED_ASSET_NUMBER
    -- ==========================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_shipped_asset_number_change_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        changes_made TEXT;
      BEGIN
        
          IF (NEW.shipped_asset_number::text <> ''::text) AND (NULLIF(trim(OLD.shipped_asset_number),'') IS NULL) THEN
            changes_made = '{ before: { shipped: false }, after: { shipped: true } }';
            EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
            USING NEW.id, 'BIN_DISPATCHED_VIA_RMT', changes_made;
          ELSIF (OLD.shipped_asset_number::text <> ''::text) AND (NULLIF(trim(NEW.shipped_asset_number),'') IS NULL) THEN
            changes_made = '{ before: { shipped: true }, after: { shipped: false } }';
            EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
            USING NEW.id, 'BIN_UNSHIPPED', changes_made;
          END IF;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_shipped_asset_number_change_to_queue()
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

    run <<~SQL
    -- ==========================================================================
    -- MONITORS PALLETS SHIPPED
    -- ==========================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_pallet_bin_shipped_change_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        oldest_seq_no INTEGER;
        bin_pallet BOOLEAN;
        bin_event_type TEXT;
        changes_made TEXT;
      BEGIN
        EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                 JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                 WHERE NOT pallets.scrapped AND pallets.id = $1'
        INTO oldest_seq_no
        USING NEW.id;
  
        EXECUTE 'SELECT EXISTS(SELECT pallet_sequences.id FROM pallet_sequences
                 JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                 JOIN grades ON grades.id = pallet_sequences.grade_id
                 WHERE pallet_sequences.pallet_id = $1 
                  AND pallet_sequences.pallet_sequence_number = $2
                  AND standard_pack_codes.bin AND grades.rmt_grade)'
        INTO bin_pallet
        USING NEW.id, oldest_seq_no;
  
          IF (bin_pallet) THEN
            IF (NEW.shipped ) THEN
              changes_made = '{ before: { shipped: false }, after: { shipped: true } }';
              bin_event_type = 'BIN_DISPATCHED_VIA_FG';
            ELSE
              changes_made = '{ before: { shipped: true }, after: { shipped: false } }';
              bin_event_type = 'BIN_UNSHIPPED_VIA_FG';
            END IF;
            EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made, pallet) VALUES($1, $2, $3, true);' 
            USING NEW.id, bin_event_type, changes_made;
          END IF;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_pallet_bin_shipped_change_to_queue()
      OWNER TO postgres;
    SQL

    run <<~SQL
    -- ==========================================================================================================================
    -- MONITORS PALLETS updates to rmt_container_material_owner_id
    -- ==========================================================================================================================
    
    CREATE OR REPLACE FUNCTION public.fn_add_pallet_bin_owner_update_to_queue()
      RETURNS trigger AS
    $BODY$
      DECLARE
        oldest_seq_no INTEGER;
        bin_pallet BOOLEAN;
        changes_made TEXT;
      BEGIN
        EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                 JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                 WHERE NOT pallets.scrapped AND pallets.id = $1'
        INTO oldest_seq_no
        USING NEW.id;
  
        EXECUTE 'SELECT EXISTS(SELECT pallet_sequences.id FROM pallet_sequences
                 JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                 JOIN grades ON grades.id = pallet_sequences.grade_id
                 WHERE pallet_sequences.pallet_id = $1 
                  AND pallet_sequences.pallet_sequence_number = $2
                  AND standard_pack_codes.bin AND grades.rmt_grade)'
        INTO bin_pallet
        USING NEW.id, oldest_seq_no;
  
          IF (bin_pallet) THEN
            IF (OLD.rmt_container_material_owner_id IS NOT NULL) OR (NEW.rmt_container_material_owner_id IS NOT NULL) THEN
              IF (NEW.rmt_container_material_owner_id <> OLD.rmt_container_material_owner_id) THEN
                changes_made = '{ before: { owner_id: ' || OLD.rmt_container_material_owner_id || '},
                                  after: { owner_id: ' || NEW.rmt_container_material_owner_id || ' } }';
                EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made, pallet) VALUES($1, $2, $3, true);' 
                         USING NEW.id, 'BIN_PALLET_MATERIAL_OWNER_CHANGED', changes_made;
              END IF;
            END IF;
          END IF;
        
        RETURN NEW; 
      END
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.fn_add_pallet_bin_owner_update_to_queue()
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
            END IF;
            EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type) VALUES($1, $2);' 
            USING OLD.id, bin_event_type;
          ELSIF (TG_OP = 'INSERT') THEN
            IF (NEW.rmt_delivery_id IS NOT NULL) THEN
              bin_event_type = 'DELIVERY_RECEIVED';
            ELSIF (NEW.production_run_rebin_id IS NOT NULL) THEN
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
      -- ==========================================================================
      -- MONITORS RMT_BINS BIN_TIPPED
      -- ==========================================================================
      
      CREATE OR REPLACE FUNCTION public.fn_add_bin_tipped_change_to_queue()
        RETURNS trigger AS
      $BODY$
        DECLARE
          bin_event_type TEXT;
          changes_made TEXT;
        BEGIN
          IF (TG_OP = 'UPDATE') THEN
            IF (NEW.bin_tipped) THEN
              changes_made = '{ before: { bin_tipped: false }, after: { bin_tipped: true } }';
              bin_event_type = 'BIN_TIPPED';
            ELSE
              changes_made = '{ before: { bin_tipped: true }, after: { bin_tipped: false } }';
              bin_event_type = 'BIN_UNTIPPED';
            END IF;
            EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
            USING NEW.id, bin_event_type, changes_made;
          END IF;
          RETURN NEW; 
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_bin_tipped_change_to_queue()
        OWNER TO postgres;
    SQL

    run <<~SQL
      -- ==========================================================================
      -- MONITORS RMT_BINS SCRAPPED
      -- ==========================================================================
      
      CREATE OR REPLACE FUNCTION public.fn_add_bin_scrapped_change_to_queue()
        RETURNS trigger AS
      $BODY$
        DECLARE
          bin_event_type TEXT;
          changes_made TEXT;
        BEGIN
          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.production_run_rebin_id IS NOT NULL) OR (NEW.production_run_rebin_id IS NOT NULL) THEN
              IF (NEW.scrapped) THEN
                changes_made = '{ before: { scrapped: false }, after: { scrapped: true } }';
                bin_event_type = 'REBIN_SCRAPPED';
              ELSE
                changes_made = '{ before: { scrapped: true }, after: { scrapped: false } }';
                bin_event_type = 'REBIN_UNSCRAPPED';
              END IF;
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, bin_event_type, changes_made;
            ELSIF (OLD.rmt_delivery_id IS NOT NULL) OR (NEW.rmt_delivery_id IS NOT NULL) THEN
                IF (NEW.scrapped) THEN
                  changes_made = '{ before: { scrapped: false }, after: { scrapped: true } }';
                  bin_event_type = 'BIN_SCRAPPED';
                ELSE
                  changes_made = '{ before: { scrapped: true }, after: { scrapped: false } }';
                  bin_event_type = 'BIN_UNSCRAPPED';
                END IF;
                EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
                USING NEW.id, bin_event_type, changes_made;
            END IF;
          END IF;
          RETURN NEW; 
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_bin_scrapped_change_to_queue()
        OWNER TO postgres;
    SQL

    run <<~SQL
      -- ==========================================================================
      -- MONITORS RMT_BINS SHIPPED_ASSET_NUMBER
      -- ==========================================================================
      
      CREATE OR REPLACE FUNCTION public.fn_add_shipped_asset_number_change_to_queue()
        RETURNS trigger AS
      $BODY$
        DECLARE
          changes_made TEXT;
        BEGIN
          IF (TG_OP = 'UPDATE') THEN
            IF (NEW.shipped_asset_number::text <> ''::text) AND (NULLIF(trim(OLD.shipped_asset_number),'') IS NULL) THEN
              changes_made = '{ before: { shipped: false }, after: { shipped: true } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'BIN_DISPATCHED_VIA_RMT', changes_made;
            ELSIF (OLD.shipped_asset_number::text <> ''::text) AND (NULLIF(trim(NEW.shipped_asset_number),'') IS NULL) THEN
              changes_made = '{ before: { shipped: true }, after: { shipped: false } }';
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
              USING NEW.id, 'BIN_UNSHIPPED', changes_made;
            END IF;
          END IF;
          RETURN NEW; 
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_shipped_asset_number_change_to_queue()
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
          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.production_run_rebin_id IS NOT NULL) OR (NEW.production_run_rebin_id IS NOT NULL) THEN
              IF (NEW.rmt_material_owner_party_role_id <> OLD.rmt_material_owner_party_role_id) OR (NEW.rmt_container_material_type_id <> OLD.rmt_container_material_type_id) THEN
                changes_made = '{ before: { rmt_material_owner_party_role_id: ' || OLD.rmt_material_owner_party_role_id || ',
                                            rmt_container_material_type_id: ' || OLD.rmt_container_material_type_id || '}, 
                                  after: { rmt_material_owner_party_role_id: ' || NEW.rmt_material_owner_party_role_id || ',
                                           rmt_container_material_type_id: ' || NEW.rmt_container_material_type_id || ' } }';
                EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made) VALUES($1, $2, $3);' 
                USING NEW.id, 'REBIN_MATERIAL_OWNER_CHANGED', changes_made;
              END IF;
            ELSIF (OLD.rmt_delivery_id IS NOT NULL) OR (NEW.rmt_delivery_id IS NOT NULL) THEN
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
          END IF;
          RETURN NEW; 
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_bin_update_to_queue()
        OWNER TO postgres;
    SQL

    run <<~SQL
      -- ==========================================================================
      -- MONITORS PALLETS SHIPPED
      -- ==========================================================================
      
      CREATE OR REPLACE FUNCTION public.fn_add_pallet_bin_shipped_change_to_queue()
        RETURNS trigger AS
      $BODY$
        DECLARE
          oldest_seq_no INTEGER;
          bin_pallet BOOLEAN;
          bin_event_type TEXT;
          changes_made TEXT;
        BEGIN
          EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   WHERE NOT pallets.scrapped AND pallets.id = $1'
          INTO oldest_seq_no
          USING NEW.id;

          EXECUTE 'SELECT EXISTS(SELECT pallet_sequences.id FROM pallet_sequences
                   JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                   JOIN grades ON grades.id = pallet_sequences.grade_id
                   WHERE pallet_sequences.pallet_id = $1 
                    AND pallet_sequences.pallet_sequence_number = $2
                    AND standard_pack_codes.bin AND grades.rmt_grade)'
          INTO bin_pallet
          USING NEW.id, oldest_seq_no;

          IF (TG_OP = 'UPDATE') THEN
            IF (bin_pallet) THEN
              IF (NEW.shipped ) THEN
                changes_made = '{ before: { shipped: false }, after: { shipped: true } }';
                bin_event_type = 'BIN_DISPATCHED_VIA_FG';
              ELSE
                changes_made = '{ before: { shipped: true }, after: { shipped: false } }';
                bin_event_type = 'BIN_UNSHIPPED_VIA_FG';
              END IF;
              EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made, pallet) VALUES($1, $2, $3, true);' 
              USING NEW.id, bin_event_type, changes_made;
            END IF;
          END IF;
          RETURN NEW; 
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_pallet_bin_shipped_change_to_queue()
        OWNER TO postgres;
    SQL

    run <<~SQL
      -- ==========================================================================================================================
      -- MONITORS PALLETS updates to rmt_container_material_owner_id
      -- ==========================================================================================================================
      
      CREATE OR REPLACE FUNCTION public.fn_add_pallet_bin_owner_update_to_queue()
        RETURNS trigger AS
      $BODY$
        DECLARE
          oldest_seq_no INTEGER;
          bin_pallet BOOLEAN;
          changes_made TEXT;
        BEGIN
          EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   WHERE NOT pallets.scrapped AND pallets.id = $1'
          INTO oldest_seq_no
          USING NEW.id;

          EXECUTE 'SELECT EXISTS(SELECT pallet_sequences.id FROM pallet_sequences
                   JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                   JOIN grades ON grades.id = pallet_sequences.grade_id
                   WHERE pallet_sequences.pallet_id = $1 
                    AND pallet_sequences.pallet_sequence_number = $2
                    AND standard_pack_codes.bin AND grades.rmt_grade)'
          INTO bin_pallet
          USING NEW.id, oldest_seq_no;

          IF (TG_OP = 'UPDATE') THEN
            IF (bin_pallet) THEN
              IF (OLD.rmt_container_material_owner_id IS NOT NULL) OR (NEW.rmt_container_material_owner_id IS NOT NULL) THEN
                IF (NEW.rmt_container_material_owner_id <> OLD.rmt_container_material_owner_id) THEN
                  changes_made = '{ before: { owner_id: ' || OLD.rmt_container_material_owner_id || '},
                                    after: { owner_id: ' || NEW.rmt_container_material_owner_id || ' } }';
                  EXECUTE 'INSERT INTO bin_asset_transactions_queue (rmt_bin_id, bin_event_type, changes_made, pallet) VALUES($1, $2, $3, true);' 
                           USING NEW.id, 'BIN_PALLET_MATERIAL_OWNER_CHANGED', changes_made;
                END IF;
              END IF;
            END IF;
          END IF;
          RETURN NEW; 
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_pallet_bin_owner_update_to_queue()
        OWNER TO postgres;
    SQL
  end
end
