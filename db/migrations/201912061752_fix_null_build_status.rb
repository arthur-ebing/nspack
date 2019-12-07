Sequel.migration do
  up do
    run <<~SQL
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

          IF (calc_build_status <> COALESCE(plt_build_status, '')) THEN
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

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_seq_build_status_calc()
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
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

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_seq_build_status_calc()
        OWNER TO postgres;
    SQL
  end
end
