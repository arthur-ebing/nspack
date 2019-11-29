Sequel.migration do
  up do
    drop_index :pallets, [:id, :pallet_number], name: :pallet_idx
    drop_index :pallet_sequences, [:pallet_id, :pallet_number, :pallet_sequence_number], name: :pallet_sequences_unique_idx

    add_index :rmt_bins, :production_run_tipped_id, name: :rmt_bins_prod_run_tip_fki
    add_index :rmt_bins, :production_run_rebin_id, name: :rmt_bins_prod_run_rebin_fki

    add_index :carton_labels, :production_run_id, name: :carton_labels_prod_run_fki
    add_index :cartons, :production_run_id, name: :cartons_prod_run_fki
    add_index :pallet_sequences, :production_run_id, name: :pallet_sequences_prod_run_fki

    alter_table(:rmt_bins) do
      drop_column :production_run_tipping_id
      drop_column :tipping
      drop_column :bin_tipping_started_date_time
    end

    run <<~SQL
      DROP TRIGGER prod_run_stats_bins_update_bin_tipped ON rmt_bins;
      DROP TRIGGER prod_run_stats_bins_update_scrapped ON rmt_bins;
      DROP TRIGGER prod_run_stats_bins_update_nett_weight ON rmt_bins;
      DROP TRIGGER rmt_bins_prod_run_stats_bins_trigger_updates ON rmt_bins;
      DROP FUNCTION public.update_prod_run_stats_bins_tipped();

      DROP TRIGGER carton_labels_prod_run_stats_trigger_updates ON public.carton_labels;
      DROP FUNCTION public.update_prod_run_stats_carton_labels_printed();

      DROP TRIGGER cartons_prod_run_stats_bins_trigger_updates ON public.cartons;
      DROP TRIGGER prod_run_stats_cartons_update_nett_weight ON public.cartons;
      DROP FUNCTION public.update_prod_run_stats_cartons_stats();
    SQL
  end

  down do
    add_index :pallets, [:id, :pallet_number], name: :pallet_idx, unique: true
    add_index :pallet_sequences, [:pallet_id, :pallet_number, :pallet_sequence_number], name: :pallet_sequences_unique_idx, unique: true

    drop_index :rmt_bins, :production_run_tipped_id, name: :rmt_bins_prod_run_tip_fki
    drop_index :rmt_bins, :production_run_rebin_id, name: :rmt_bins_prod_run_rebin_fki

    drop_index :carton_labels, :production_run_id, name: :carton_labels_prod_run_fki
    drop_index :cartons, :production_run_id, name: :cartons_prod_run_fki
    drop_index :pallet_sequences, :production_run_id, name: :pallet_sequences_prod_run_fki

    alter_table(:rmt_bins) do
      add_column :production_run_tipping_id, Integer
      add_column :tipping, TrueClass, default: false
      add_column :bin_tipping_started_date_time, DateTime
    end

    run <<~SQL
      -- ==============================================================================
      -- RMT_BINS
      -- ==============================================================================

        CREATE OR REPLACE FUNCTION public.update_prod_run_stats_bins_tipped()
           RETURNS trigger AS
        $BODY$
           DECLARE
           BEGIN

            IF (TG_OP = 'UPDATE') THEN
              IF (NEW.bin_tipped <> OLD.bin_tipped) THEN
                IF (NEW.bin_tipped IS TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped + $2), bins_tipped_weight = (bins_tipped_weight + $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                ELSIF (NEW.bin_tipped IS NOT TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped - $2), bins_tipped_weight = (bins_tipped_weight - $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                END IF;
              END IF;
              
              IF (NEW.scrapped <> OLD.scrapped) THEN
                IF (NEW.scrapped IS TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped - $2), bins_tipped_weight = (bins_tipped_weight - $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                ELSIF (NEW.scrapped IS NOT TRUE) THEN
                  EXECUTE 'UPDATE production_run_stats set bins_tipped = (bins_tipped + $2), bins_tipped_weight = (bins_tipped_weight + $3)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_tipped_id, NEW.qty_bins, NEW.nett_weight;
                END IF;
              END IF;

              IF (OLD.nett_weight IS NULL AND NEW.nett_weight IS NOT NULL) OR (NEW.nett_weight <> OLD.nett_weight) THEN
                IF (NEW.production_run_rebin_id IS NOT NULL) THEN
                  EXECUTE 'UPDATE production_run_stats set rebins_weight = (rebins_weight + $2)
                           WHERE production_run_id = $1'
                  USING NEW.production_run_rebin_id, NEW.nett_weight - OLD.nett_weight;
                END IF;
              END IF;
            ELSIF (TG_OP = 'INSERT') THEN
              EXECUTE 'UPDATE production_run_stats set rebins_created = (rebins_created + $2), rebins_weight = (rebins_weight + $3)
                       WHERE production_run_id = $1'
              USING NEW.production_run_rebin_id, NEW.qty_bins, NEW.nett_weight;
            END IF;

          RETURN NEW;

        END

        $BODY$
          LANGUAGE plpgsql VOLATILE
          COST 100;
        ALTER FUNCTION public.update_prod_run_stats_bins_tipped()
          OWNER TO postgres;

        CREATE TRIGGER prod_run_stats_bins_update_bin_tipped
        AFTER UPDATE OF bin_tipped 
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();

        CREATE TRIGGER prod_run_stats_bins_update_scrapped
        AFTER UPDATE OF scrapped 
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();

        CREATE TRIGGER prod_run_stats_bins_update_nett_weight
        BEFORE UPDATE OF nett_weight 
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE update_prod_run_stats_bins_tipped();

        CREATE TRIGGER rmt_bins_prod_run_stats_bins_trigger_updates
        BEFORE INSERT
        ON public.rmt_bins
        FOR EACH ROW
        EXECUTE PROCEDURE public.update_prod_run_stats_bins_tipped();

      -- ==============================================================================
      -- CARTON LABELS
      -- ==============================================================================

      CREATE OR REPLACE FUNCTION public.update_prod_run_stats_carton_labels_printed()
        RETURNS trigger AS
      $BODY$
        DECLARE
        BEGIN
          IF (TG_OP = 'INSERT') THEN
            EXECUTE 'UPDATE production_run_stats set carton_labels_printed = carton_labels_printed + 1
                     WHERE production_run_id = $1'
            USING NEW.production_run_id;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.update_prod_run_stats_carton_labels_printed()
        OWNER TO postgres;

      CREATE TRIGGER carton_labels_prod_run_stats_trigger_updates
      AFTER INSERT
      ON public.carton_labels
      FOR EACH ROW
      EXECUTE PROCEDURE public.update_prod_run_stats_carton_labels_printed();

      -- ==============================================================================
      -- CARTONS
      -- ==============================================================================

      CREATE OR REPLACE FUNCTION public.update_prod_run_stats_cartons_stats()
        RETURNS trigger AS
      $BODY$
        DECLARE
          old_nett_weight DECIMAL;
        BEGIN

          IF (TG_OP = 'INSERT') THEN
            EXECUTE 'UPDATE production_run_stats set cartons_verified = (cartons_verified + 1), cartons_verified_weight = (cartons_verified_weight + COALESCE($2, 0))
                     WHERE production_run_id = $1'
            USING NEW.production_run_id, NEW.nett_weight;
          ELSIF (TG_OP = 'UPDATE') THEN
            IF (OLD.nett_weight IS NULL AND NEW.nett_weight IS NOT NULL) OR (NEW.nett_weight <> OLD.nett_weight) THEN
              IF (OLD.nett_weight IS NULL) THEN  
                old_nett_weight = 0; 
              ELSE
                old_nett_weight = OLD.nett_weight; 
              END IF;
              IF (NEW.nett_weight > old_nett_weight) THEN
                EXECUTE 'UPDATE production_run_stats set cartons_verified_weight = (cartons_verified_weight + $2)
                         WHERE production_run_id = $1'
                USING NEW.production_run_id, NEW.nett_weight - old_nett_weight;
              ELSIF (NEW.nett_weight < old_nett_weight) THEN
                EXECUTE 'UPDATE production_run_stats set cartons_verified_weight = (cartons_verified_weight - $2)
                         WHERE production_run_id = $1'
                USING NEW.production_run_id, old_nett_weight - NEW.nett_weight;
              END IF;
            END IF;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.update_prod_run_stats_cartons_stats()
        OWNER TO postgres;

      CREATE TRIGGER cartons_prod_run_stats_bins_trigger_updates
      AFTER INSERT
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE public.update_prod_run_stats_cartons_stats();

      CREATE TRIGGER prod_run_stats_cartons_update_nett_weight
      AFTER UPDATE OF nett_weight 
      ON public.cartons
      FOR EACH ROW
      EXECUTE PROCEDURE update_prod_run_stats_cartons_stats();
    SQL
  end
end
