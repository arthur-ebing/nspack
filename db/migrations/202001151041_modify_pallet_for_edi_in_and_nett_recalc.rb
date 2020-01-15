Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :depot_pallet, TrueClass, default: false
      add_foreign_key :edi_in_transaction_id, :edi_in_transactions, type: :integer
      add_column :edi_in_consignment_note_number, String
      add_column :re_calculate_nett, TrueClass, default: false
    end

    run <<~SQL
      -- Function: calculate nett weight for pallet

      CREATE OR REPLACE FUNCTION public.fn_pallet_nett_weight_calc()
        RETURNS trigger AS
      $BODY$
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
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_nett_weight_calc()
        OWNER TO postgres;

      -- Trigger: calculate nett weight for pallet

      DROP TRIGGER pallets_update_nett_weight ON public.pallets;

      CREATE TRIGGER pallets_update_nett_weight
        BEFORE UPDATE OF gross_weight, pallet_format_id, re_calculate_nett
        ON public.pallets
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_pallet_nett_weight_calc();
    SQL
  end

  down do
    run <<~SQL
      -- Function: calculate nett weight for pallet

      CREATE OR REPLACE FUNCTION public.fn_pallet_nett_weight_calc()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (NEW.gross_weight IS NOT NULL) THEN
            NEW.nett_weight = fn_calculate_pallet_nett_weight(NEW.id, NEW.gross_weight);
            EXECUTE 'UPDATE pallet_sequences SET nett_weight = (carton_quantity / $2::numeric) * $3
                     WHERE pallet_id = $1'
            USING NEW.id, NEW.carton_quantity, NEW.nett_weight;         
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_pallet_nett_weight_calc()
        OWNER TO postgres;

      -- Trigger: calculate nett weight for pallet

      DROP TRIGGER pallets_update_nett_weight ON public.pallets;

      CREATE TRIGGER pallets_update_nett_weight
        BEFORE UPDATE OF gross_weight, pallet_format_id
        ON public.pallets
        FOR EACH ROW
        EXECUTE PROCEDURE public.fn_pallet_nett_weight_calc();
    SQL

    alter_table(:pallets) do
      drop_column :depot_pallet
      drop_foreign_key :edi_in_transaction_id
      drop_column :edi_in_consignment_note_number
      drop_column :re_calculate_nett
    end
  end
end
