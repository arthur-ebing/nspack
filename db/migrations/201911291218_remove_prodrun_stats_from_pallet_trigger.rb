Sequel.migration do
  up do
    run <<~SQL
      DROP TRIGGER pallets_update_gross_weight ON public.pallets;
      DROP TRIGGER pallets_before_update_scrapped ON public.pallets;
      DROP TRIGGER pallets_after_update_scrapped ON public.pallets;
      DROP TRIGGER pallets_update_build_status ON public.pallets;
      DROP TRIGGER pallets_update_inspected ON public.pallets;
      DROP FUNCTION public.fn_pallet_trigger_updates();

      DROP TRIGGER pallet_sequences_pallets_trigger_updates ON public.pallet_sequences;
      DROP TRIGGER pallet_sequences_update_carton_quantity ON public.pallet_sequences;
      DROP FUNCTION public.fn_ps_pallet_trigger_updates();

      -- =========================================================
      -- PALLET: Calculate Nett on change of Gross / Pallet Format
      -- =========================================================

      CREATE OR REPLACE FUNCTION public.fn_pallet_nett_weight_calc()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (NEW.gross_weight IS NOT NULL) THEN
            NEW.nett_weight = fn_calculate_pallet_nett_weight(NEW.id, NEW.gross_weight);
            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                     WHERE pallet_id = $1'
            USING NEW.id, NEW.carton_quantity, NEW.nett_weight;         
          ELSE
            EXECUTE 'UPDATE pallet_sequences SET nett_weight = NULL WHERE pallet_id = $1'
            USING NEW.id;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_nett_weight_calc()
        OWNER TO postgres;

      CREATE TRIGGER pallets_update_nett_weight
      BEFORE UPDATE OF gross_weight, pallet_format_id
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_nett_weight_calc();

      -- ===================================================================
      -- PALLET SEQUENCE: Calculate Nett on insert / change of STD pack, qty
      -- ===================================================================

      CREATE OR REPLACE FUNCTION public.fn_pallet_seq_nett_weight_calc()
        RETURNS trigger AS
      $BODY$
        DECLARE
          plt_qty INTEGER;
          plt_gross DECIMAL;
          plt_nett DECIMAL;
          other_qty INTEGER;
          tot_qty INTEGER;
          calc_nett DECIMAL;
        BEGIN
          EXECUTE 'SELECT carton_quantity, gross_weight, nett_weight FROM pallets WHERE id = $1'
          INTO plt_qty, plt_gross, plt_nett
          USING NEW.pallet_id;

          EXECUTE 'SELECT COALESCE(SUM(carton_quantity), 0) FROM pallet_sequences WHERE pallet_id = $1 AND id <> COALESCE($2, -1)'
          INTO other_qty
          USING NEW.pallet_id, NEW.id;

          IF (NEW.carton_quantity IS NULL) THEN
            tot_qty = other_qty;
          ELSE
            tot_qty = other_qty + NEW.carton_quantity;
          END IF;
          calc_nett = fn_calculate_pallet_nett_weight(NEW.pallet_id, plt_gross);

          IF (calc_nett <> plt_nett) THEN
            EXECUTE 'UPDATE pallets SET nett_weight = $2 WHERE id = $1'
            USING NEW.pallet_id, calc_nett;

            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                     WHERE pallet_id = $1
                       AND id <> COALESCE($4, -1)
                       AND carton_quantity <> 0'
            USING NEW.pallet_id, tot_qty, calc_nett, NEW.id;
          END IF;

          -- SHOULD A SEQ HAVE ITS NETT SET TO ZERO ON SCRAP?
          IF (NEW.carton_quantity <> 0) THEN
            NEW.nett_weight = NEW.carton_quantity / tot_qty * calc_nett;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_seq_nett_weight_calc()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_update_nett_weight
      BEFORE INSERT OR UPDATE OF standard_pack_code_id, carton_quantity
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_seq_nett_weight_calc();

      -- =============================================================================
      -- PALLET SEQUENCE: Calculate Pallet build status on insert / change of CPP, qty
      -- =============================================================================

      CREATE OR REPLACE FUNCTION public.fn_pallet_seq_build_status_calc()
        RETURNS trigger AS
      $BODY$
        DECLARE
          plt_qty INTEGER;
          plt_build_status TEXT;
          calc_build_status TEXT;
          other_qty INTEGER;
          tot_qty INTEGER;
          cpp_id INTEGER;
          cartons_per_pallet INTEGER;
        BEGIN
          EXECUTE 'SELECT carton_quantity, build_status FROM pallets WHERE id = $1'
          INTO plt_qty, plt_build_status
          USING NEW.pallet_id;

          EXECUTE 'SELECT COALESCE(SUM(carton_quantity), 0) FROM pallet_sequences WHERE pallet_id = $1 AND id <> COALESCE($2, -1)'
          INTO other_qty
          USING NEW.pallet_id, NEW.id;

          IF (NEW.carton_quantity IS NULL) THEN
            tot_qty = other_qty;
          ELSE
            tot_qty = other_qty + NEW.carton_quantity;
          END IF;

          IF (plt_qty <> tot_qty) THEN
            EXECUTE 'SELECT cartons_per_pallet_id
                     FROM pallet_Sequences
                     WHERE id = (SELECT MIN(pallet_sequence_number)
                                 FROM pallet_sequences
                                 WHERE pallet_id = $1
                                   AND scrapped_at IS NULL)'
            INTO cpp_id
            USING NEW.pallet_id;

            EXECUTE 'SELECT cartons_per_pallet
                     FROM cartons_per_pallet
                     WHERE id = $1'
            INTO cartons_per_pallet
            USING COALESCE(cpp_id, NEW.cartons_per_pallet_id);

            IF (cartons_per_pallet IS NULL) THEN
                RAISE EXCEPTION 'Cannot calculate a build_status. There is no cartons_per_pallet set';
            END IF;

            calc_build_status = fn_calculate_pallet_build_status(tot_qty, cartons_per_pallet);

            IF (calc_build_status <> plt_build_status) THEN
              CASE calc_build_status
                WHEN 'FULL' THEN
                  EXECUTE 'UPDATE pallets SET build_status = $2, palletized = true, partially_palletized = false, palletized_at = $3, carton_quantity = $4
                           WHERE id = $1'
                  USING NEW.pallet_id, calc_build_status, current_timestamp, tot_qty;
                WHEN 'PARTIAL', 'OVERFULL' THEN
                  EXECUTE 'UPDATE pallets SET build_status = $2, palletized = false, partially_palletized = true, partially_palletized_at = $3, carton_quantity = $4
                           WHERE id = $1'
                  USING NEW.pallet_id, calc_build_status, current_timestamp, tot_qty;
              END CASE;
            ELSE
              EXECUTE 'UPDATE pallets SET carton_quantity = $2 WHERE id = $1'
              USING NEW.pallet_id, tot_qty;
            END IF;
          END IF;

          -- [[[[[ WHAT IF pseq moved from one pallet to another... Will this fire?  ]]]]]

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_seq_build_status_calc()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_update_pallet_build_status
      BEFORE INSERT OR UPDATE OF cartons_per_pallet_id, carton_quantity
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_seq_build_status_calc();

      -- ======================================================================
      -- CHANGE nett weight calculation to ignore scrapped sequences (qty == 0)
      -- ======================================================================

      CREATE OR REPLACE FUNCTION public.fn_calculate_pallet_nett_weight(
          in_id integer,
          plt_gross_weight numeric)
        RETURNS numeric AS
      $BODY$
        DECLARE
          plt_std_pack_material_mass DECIMAL;
          plt_base_material_mass DECIMAL;
        BEGIN
          EXECUTE 'SELECT COALESCE(SUM(standard_pack_codes.material_mass), 0)
                   FROM pallet_sequences
                   JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                   WHERE pallet_sequences.pallet_id = $1
                     AND pallet_sequences.carton_quantity <> 0'
          INTO plt_std_pack_material_mass
          USING in_id;

          EXECUTE 'SELECT COALESCE(pallet_bases.material_mass, 0)
                   FROM pallets
                   LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
                   LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
                   WHERE pallets.id = $1'
          INTO plt_base_material_mass
          USING in_id;

          RETURN plt_gross_weight - (plt_std_pack_material_mass + plt_base_material_mass);
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_calculate_pallet_nett_weight(integer, numeric)
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_pallet_trigger_updates()
        RETURNS trigger AS
      $BODY$
        DECLARE
          plt_carton_quantity DECIMAL;
          plt_first_ps INTEGER;
          plt_first_ps_pdn_run_id INTEGER;
        BEGIN
          EXECUTE 'SELECT carton_quantity FROM pallets WHERE id = $1'
          INTO plt_carton_quantity
          USING NEW.id;

          EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   WHERE NOT pallets.scrapped AND pallets.id = $1'
          INTO plt_first_ps
          USING NEW.id;

          EXECUTE 'SELECT production_run_id FROM pallet_sequences
                   WHERE pallet_id = $1 AND pallet_sequence_number = $2'
          INTO plt_first_ps_pdn_run_id
          USING NEW.id, plt_first_ps;

          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.gross_weight IS NULL AND NEW.gross_weight IS NOT NULL) OR (NEW.gross_weight <> OLD.gross_weight) THEN
              NEW.nett_weight = fn_calculate_pallet_nett_weight(OLD.id, NEW.gross_weight);
              EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2) * $3
                       WHERE pallet_id = $1'
              USING NEW.id, plt_carton_quantity, NEW.nett_weight;         
            END IF;

            IF (NEW.scrapped <> OLD.scrapped) THEN
              IF (NEW.scrapped IS TRUE) THEN
                IF (NEW.palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_full = (pallets_palletized_full - 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                ELSIF (NEW.partially_palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial - 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                END IF;
              ELSIF (NEW.scrapped IS NOT TRUE) THEN
                IF (NEW.palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_full = (pallets_palletized_full + 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                ELSIF (NEW.partially_palletized IS TRUE) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial + 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                END IF;
              END IF;
            END IF;

            IF (OLD.build_status IS NULL AND NEW.build_status IS NOT NULL) OR (NEW.build_status <> OLD.build_status) THEN
              CASE NEW.build_status
                WHEN 'FULL' THEN
                  EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial - 1),
                           pallets_palletized_full = (pallets_palletized_full + 1)
                           WHERE production_run_id = $1'
                  USING plt_first_ps_pdn_run_id;
                WHEN 'PARTIAL', 'OVERFULL' THEN
                  IF (OLD.build_status = 'FULL'::text) THEN
                    EXECUTE 'UPDATE production_run_stats SET pallets_palletized_partial = (pallets_palletized_partial + 1),
                             pallets_palletized_full = (pallets_palletized_full - 1)
                             WHERE production_run_id = $1'
                    USING plt_first_ps_pdn_run_id;
                  END IF;
              END CASE;
            END IF;

            IF (NEW.inspected <> OLD.inspected) THEN
              IF (NEW.inspected IS TRUE) THEN
                EXECUTE 'UPDATE production_run_stats SET inspected_pallets = (inspected_pallets + 1)
                         WHERE production_run_id = $1'
                USING plt_first_ps_pdn_run_id;
              ELSIF (NEW.inspected IS NOT TRUE) THEN
                EXECUTE 'UPDATE production_run_stats SET inspected_pallets = (inspected_pallets - 1)
                         WHERE production_run_id = $1'
                USING plt_first_ps_pdn_run_id;
              END IF;
            END IF;

          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_trigger_updates()
        OWNER TO postgres;

      CREATE TRIGGER pallets_update_gross_weight
      BEFORE UPDATE OF gross_weight
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_before_update_scrapped
      BEFORE UPDATE OF scrapped
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_after_update_scrapped
      AFTER UPDATE OF scrapped
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_update_build_status
      AFTER UPDATE OF build_status
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      CREATE TRIGGER pallets_update_inspected
      AFTER UPDATE OF inspected
      ON public.pallets
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_trigger_updates();

      DROP TRIGGER pallets_update_nett_weight ON public.pallets;
      DROP FUNCTION public.fn_pallet_nett_weight_calc();

      DROP TRIGGER pallet_sequences_update_nett_weight ON public.pallet_sequences;
      DROP FUNCTION public.fn_pallet_seq_nett_weight_calc();

      DROP TRIGGER pallet_sequences_update_pallet_build_status ON public.pallet_sequences;
      DROP FUNCTION public.fn_pallet_seq_build_status_calc();


      CREATE OR REPLACE FUNCTION public.fn_calculate_pallet_nett_weight(
          in_id integer,
          plt_gross_weight numeric)
        RETURNS numeric AS
      $BODY$
        DECLARE
          plt_std_pack_material_mass DECIMAL;
          plt_base_material_mass DECIMAL;
        BEGIN
          EXECUTE 'SELECT COALESCE(SUM(standard_pack_codes.material_mass), 0)
                   FROM pallets
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
                   WHERE pallets.id = $1'
          INTO plt_std_pack_material_mass
          USING in_id;

          EXECUTE 'SELECT COALESCE(pallet_bases.material_mass, 0)
                   FROM pallets
                   LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
                   LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
                   WHERE pallets.id = $1'
          INTO plt_base_material_mass
          USING in_id;

          RETURN plt_gross_weight - (plt_std_pack_material_mass + plt_base_material_mass);
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_calculate_pallet_nett_weight(integer, numeric)
        OWNER TO postgres;


      CREATE OR REPLACE FUNCTION public.fn_ps_pallet_trigger_updates()
        RETURNS trigger AS
      $BODY$
        DECLARE
          plt_ps_carton_quantity DECIMAL;
          plt_first_ps INTEGER;
          cartons_per_pallet INTEGER;
          plt_carton_quantity DECIMAL;
          plt_build_status TEXT;
          plt_nett_weight DECIMAL;
          
        BEGIN

          IF (TG_OP = 'UPDATE') THEN
            EXECUTE 'SELECT sum(carton_quantity) FROM pallet_sequences WHERE pallet_id = $1 AND id NOT IN ($2)'
            INTO plt_ps_carton_quantity
            USING OLD.pallet_id, NEW.id;

            EXECUTE 'SELECT COALESCE(nett_weight, 0) FROM pallets WHERE id = $1'
            INTO plt_nett_weight
            USING OLD.pallet_id;
          ELSIF (TG_OP = 'INSERT') THEN
            EXECUTE 'SELECT sum(carton_quantity) FROM pallet_sequences WHERE pallet_id = $1'
            INTO plt_ps_carton_quantity
            USING NEW.pallet_id;

            EXECUTE 'SELECT COALESCE(nett_weight, 0) FROM pallets WHERE id = $1'
            INTO plt_nett_weight
            USING NEW.pallet_id;
          END IF;

          IF (plt_ps_carton_quantity IS NULL) THEN
            plt_carton_quantity = NEW.carton_quantity;
          ELSE
            plt_carton_quantity = plt_ps_carton_quantity + NEW.carton_quantity;
          END IF;

          IF (plt_carton_quantity IS NULL) THEN
              RAISE EXCEPTION 'Cannot calculate a build_status. There is no plt_carton_quantity set';
          END IF;

          EXECUTE 'SELECT MIN(pallet_sequence_number) FROM pallets 
                   JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
                   WHERE NOT pallets.scrapped AND pallets.id = $1'
          INTO plt_first_ps
          USING NEW.pallet_id;

          IF (plt_first_ps IS NOT NULL) THEN
            EXECUTE 'SELECT cartons_per_pallet FROM cartons_per_pallet
                     JOIN pallet_sequences ON cartons_per_pallet.id = pallet_sequences.cartons_per_pallet_id
                     WHERE pallet_sequences.pallet_id = $1 AND pallet_sequence_number = $2'
            INTO cartons_per_pallet
            USING NEW.pallet_id, plt_first_ps;
          END IF; 

          IF (cartons_per_pallet IS NULL) THEN
            EXECUTE 'SELECT cartons_per_pallet FROM cartons_per_pallet
                     WHERE cartons_per_pallet.id = $1'
            INTO cartons_per_pallet
            USING NEW.cartons_per_pallet_id; 
          END IF; 

          IF (cartons_per_pallet IS NULL) THEN
              RAISE EXCEPTION 'Cannot calculate a build_status. There is no cartons_per_pallet set';
          END IF;

          plt_build_status = fn_calculate_pallet_build_status(plt_carton_quantity, cartons_per_pallet);

          IF (TG_OP = 'UPDATE') THEN
            IF (OLD.carton_quantity IS NULL AND NEW.carton_quantity IS NOT NULL) OR (NEW.carton_quantity <> OLD.carton_quantity) THEN
              CASE plt_build_status
                WHEN 'FULL' THEN
                  EXECUTE 'UPDATE pallets SET build_status = $2, palletized = true, palletized_at = $3, carton_quantity = $4
                           WHERE id = $1'
                  USING OLD.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
                WHEN 'PARTIAL', 'OVERFULL' THEN
                  EXECUTE 'UPDATE pallets SET build_status = $2, partially_palletized = true, partially_palletized_at = $3, carton_quantity = $4
                           WHERE id = $1'
                  USING OLD.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
              END CASE;
              EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2) * $3
                       WHERE pallet_id = $1'
              USING OLD.pallet_id, plt_carton_quantity, plt_nett_weight;
            END IF;
          ELSIF (TG_OP = 'INSERT') THEN
            CASE plt_build_status
              WHEN 'FULL' THEN
                EXECUTE 'UPDATE pallets SET build_status = $2, palletized = true, palletized_at = $3, carton_quantity = $4
                         WHERE id = $1'
                USING NEW.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
              WHEN 'PARTIAL', 'OVERFULL' THEN
                EXECUTE 'UPDATE pallets SET build_status = $2, partially_palletized = true, partially_palletized_at = $3, carton_quantity = $4
                         WHERE id = $1'
                USING NEW.pallet_id, plt_build_status, current_timestamp, plt_carton_quantity;
            END CASE;
            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2) * $3
                     WHERE pallet_id = $1'
            USING NEW.pallet_id, plt_carton_quantity, plt_nett_weight;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_ps_pallet_trigger_updates()
        OWNER TO postgres;



      CREATE TRIGGER pallet_sequences_pallets_trigger_updates
        BEFORE INSERT
        ON public.pallet_sequences
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_ps_pallet_trigger_updates();

      CREATE TRIGGER pallet_sequences_update_carton_quantity
        AFTER UPDATE OF carton_quantity
        ON public.pallet_sequences
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_ps_pallet_trigger_updates();
    SQL
  end
end
