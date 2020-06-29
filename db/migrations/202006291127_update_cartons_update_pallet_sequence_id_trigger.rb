
Sequel.migration do
  up do
    run <<~SQL
      DROP TRIGGER cartons_update_pallet_sequence_id ON cartons;
      DROP FUNCTION fn_cartons_carton_quantity_calc();

      CREATE OR REPLACE FUNCTION public.fn_cartons_carton_quantity_calc()
      RETURNS trigger AS $BODY$
    
      DECLARE
       
      BEGIN
        IF (TG_OP = 'UPDATE') THEN
          IF (OLD.pallet_sequence_id IS NOT NULL) THEN
            EXECUTE 'UPDATE pallet_sequences SET carton_quantity = (carton_quantity - 1)
                     WHERE id = $1'
            USING OLD.pallet_sequence_id;

          END IF;

          IF (NEW.pallet_sequence_id IS NOT NULL) THEN
            EXECUTE 'UPDATE pallet_sequences SET carton_quantity = (carton_quantity + 1)
                     WHERE id = $1'
            USING NEW.pallet_sequence_id;

          END IF;
        END IF;
        RETURN NEW;
      END
    
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_cartons_carton_quantity_calc()
        OWNER TO postgres;
  
      CREATE TRIGGER cartons_update_pallet_sequence_id
        BEFORE UPDATE OF pallet_sequence_id
        ON public.cartons
        FOR EACH ROW
        EXECUTE PROCEDURE fn_cartons_carton_quantity_calc();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER cartons_update_pallet_sequence_id ON cartons;
      DROP FUNCTION fn_cartons_carton_quantity_calc();
    SQL
  end

end
