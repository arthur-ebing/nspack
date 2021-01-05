Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_pallet_nett_weight_calc()
          RETURNS trigger
          LANGUAGE 'plpgsql'
          COST 100
          VOLATILE NOT LEAKPROOF
      AS $BODY$
      BEGIN
          IF (NEW.nett_weight_externally_calculated <> true) THEN
            IF (NEW.gross_weight IS NOT NULL) THEN
              NEW.nett_weight = fn_calculate_pallet_nett_weight(NEW.id, NEW.gross_weight);
              EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                       WHERE pallet_id = $1'
              USING NEW.id, NEW.carton_quantity, NEW.nett_weight;         
            END IF;
          END IF;

          -- Reset the re_calculate flag if it was true:
          NEW.re_calculate_nett = false;

          RETURN NEW;
        END
      $BODY$;
    SQL

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_pallet_seq_nett_weight_calc()
          RETURNS trigger
          LANGUAGE 'plpgsql'
          COST 100
          VOLATILE NOT LEAKPROOF
      AS $BODY$
      DECLARE
          plt_qty INTEGER;
          plt_gross NUMERIC;
          plt_nett NUMERIC;
          other_nett NUMERIC;
          other_qty INTEGER;
          tot_qty INTEGER;
          calc_nett NUMERIC;
          std_pack_material_mass NUMERIC;
          ext_weight BOOLEAN;
        BEGIN
          EXECUTE 'SELECT carton_quantity, gross_weight, nett_weight, nett_weight_externally_calculated FROM pallets WHERE id = $1'
          INTO plt_qty, plt_gross, plt_nett, ext_weight
          USING NEW.pallet_id;

          IF (plt_gross IS NOT NULL AND ext_weight <> true) THEN
            EXECUTE 'SELECT COALESCE(SUM(carton_quantity), 0) FROM pallet_sequences WHERE pallet_id = $1 AND id <> COALESCE($2, -1)'
            INTO other_qty
            USING NEW.pallet_id, NEW.id;

            IF (NEW.carton_quantity IS NULL) THEN
              tot_qty = other_qty;
            ELSE
              tot_qty = other_qty + NEW.carton_quantity;
            END IF;
            other_nett = fn_calculate_pallet_nett_weight_without_seq(NEW.pallet_id, NEW.id, plt_gross);

            EXECUTE 'SELECT material_mass
                     FROM standard_pack_codes
                     WHERE id = $1'
            INTO std_pack_material_mass
            USING NEW.standard_pack_code_id;

            calc_nett = other_nett - COALESCE((NEW.carton_quantity * std_pack_material_mass), 0);

            IF (calc_nett <> plt_nett) THEN
              EXECUTE 'UPDATE pallets SET nett_weight = $2 WHERE id = $1'
              USING NEW.pallet_id, calc_nett;
            END IF;

            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                     WHERE pallet_id = $1
                       AND id <> COALESCE($4, -1)
                       AND carton_quantity <> 0'
            USING NEW.pallet_id, tot_qty, calc_nett, NEW.id;

            IF (NEW.carton_quantity = 0) THEN
              NEW.nett_weight = 0;
            ELSE
              NEW.nett_weight = NEW.carton_quantity / tot_qty::numeric * calc_nett;
            END IF;
          END IF;

          RETURN NEW;
        END
      $BODY$;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_pallet_nett_weight_calc()
          RETURNS trigger
          LANGUAGE 'plpgsql'
          COST 100
          VOLATILE NOT LEAKPROOF
      AS $BODY$
      BEGIN
          IF (NEW.gross_weight IS NOT NULL) THEN
            NEW.nett_weight = fn_calculate_pallet_nett_weight(NEW.id, NEW.gross_weight);
            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                     WHERE pallet_id = $1'
            USING NEW.id, NEW.carton_quantity, NEW.nett_weight;         
          END IF;

          -- Reset the re_calculate flag if it was true:
          NEW.re_calculate_nett = false;

          RETURN NEW;
        END
      $BODY$;
    SQL

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_pallet_seq_nett_weight_calc()
          RETURNS trigger
          LANGUAGE 'plpgsql'
          COST 100
          VOLATILE NOT LEAKPROOF
      AS $BODY$
      DECLARE
          plt_qty INTEGER;
          plt_gross NUMERIC;
          plt_nett NUMERIC;
          other_nett NUMERIC;
          other_qty INTEGER;
          tot_qty INTEGER;
          calc_nett NUMERIC;
          std_pack_material_mass NUMERIC;
        BEGIN
          EXECUTE 'SELECT carton_quantity, gross_weight, nett_weight FROM pallets WHERE id = $1'
          INTO plt_qty, plt_gross, plt_nett
          USING NEW.pallet_id;

          IF (plt_gross IS NOT NULL) THEN
            EXECUTE 'SELECT COALESCE(SUM(carton_quantity), 0) FROM pallet_sequences WHERE pallet_id = $1 AND id <> COALESCE($2, -1)'
            INTO other_qty
            USING NEW.pallet_id, NEW.id;

            IF (NEW.carton_quantity IS NULL) THEN
              tot_qty = other_qty;
            ELSE
              tot_qty = other_qty + NEW.carton_quantity;
            END IF;
            other_nett = fn_calculate_pallet_nett_weight_without_seq(NEW.pallet_id, NEW.id, plt_gross);

            EXECUTE 'SELECT material_mass
                     FROM standard_pack_codes
                     WHERE id = $1'
            INTO std_pack_material_mass
            USING NEW.standard_pack_code_id;

            calc_nett = other_nett - COALESCE((NEW.carton_quantity * std_pack_material_mass), 0);

            IF (calc_nett <> plt_nett) THEN
              EXECUTE 'UPDATE pallets SET nett_weight = $2 WHERE id = $1'
              USING NEW.pallet_id, calc_nett;
            END IF;

            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                     WHERE pallet_id = $1
                       AND id <> COALESCE($4, -1)
                       AND carton_quantity <> 0'
            USING NEW.pallet_id, tot_qty, calc_nett, NEW.id;

            IF (NEW.carton_quantity = 0) THEN
              NEW.nett_weight = 0;
            ELSE
              NEW.nett_weight = NEW.carton_quantity / tot_qty::numeric * calc_nett;
            END IF;
          END IF;

          RETURN NEW;
        END
      $BODY$;
    SQL
  end
end
