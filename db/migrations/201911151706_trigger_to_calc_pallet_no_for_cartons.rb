Sequel.migration do
  up do
    # Function and trigger to calculate the next available pallet number for cartons that behave exactly like pallets.

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.carton_labels_next_pallet_number()
        RETURNS trigger AS
      $BODY$
        DECLARE
          p_gln TEXT;
          p_seq_len INTEGER;
          p_next_val TEXT;
          p_seq_name TEXT;
          p_seq TEXT;
          p_pallet_base_number TEXT;
        BEGIN
          -- Get out immediately if this carton does not become a pallet...
          IF (NOT NEW.carton_equals_pallet) THEN
            RETURN NEW;
          END IF;

          EXECUTE 'SELECT resource_properties ->> ''gln''
          FROM plant_resources
          WHERE id = $1'
          INTO p_gln
          USING NEW.production_line_id;

          IF (p_gln IS NULL) THEN
              RAISE EXCEPTION 'Cannot generate a pallet number. There is no GLN for packhouse id %, line id %.', NEW.packhouse_resource_id, NEW.production_line_id;
          END IF;

          p_seq_len = 17 - length(p_gln); -- no of digits to pad to

          p_seq_name = 'gln_seq_for_' || p_gln;
          EXECUTE format('SELECT nextval(''%I'')::text AS seq'::text, p_seq_name) INTO p_next_val ;

          IF (length(p_next_val) > p_seq_len) THEN
            RAISE EXCEPTION 'Cannot generate a pallet number. The sequence % has overflowed. It needs to be reset or a new GLN number is required', p_seq_name;
          END IF;

          EXECUTE format('SELECT lpad(''%s'', %s, ''0'') AS seq'::text, p_next_val, p_seq_len) INTO p_seq;

          p_pallet_base_number = p_gln || p_seq;
          NEW.pallet_number = fn_sscc_number_with_check_digit(p_pallet_base_number);

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.carton_labels_next_pallet_number()
        OWNER TO postgres;

      CREATE TRIGGER carton_labels_next_pallet_number
      BEFORE INSERT
      ON public.carton_labels
      FOR EACH ROW
      EXECUTE PROCEDURE public.carton_labels_next_pallet_number();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER carton_labels_next_pallet_number ON public.carton_labels;
      DROP FUNCTION public.carton_labels_next_pallet_number();  
    SQL
  end
end
