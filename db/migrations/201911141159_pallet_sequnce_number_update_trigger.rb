Sequel.migration do
  up do
    # Function and trigger to calculate the next available pallet sequence number.

    run <<~SQL
      DROP TRIGGER pallet_sequences_next_pallet_sequence_number ON public.pallet_sequences;
      DROP FUNCTION public.pallet_sequences_next_pallet_sequence_number();

      CREATE OR REPLACE FUNCTION public.pallet_sequences_next_pallet_sequence_number()
        RETURNS trigger AS
      $BODY$
        DECLARE
          next_pallet_sequence_number INTEGER;
        BEGIN
          EXECUTE 'SELECT count(id) + 1
          FROM pallet_sequences
          WHERE pallet_number = $1'
          INTO next_pallet_sequence_number
          USING NEW.pallet_number;

          NEW.pallet_sequence_number = next_pallet_sequence_number;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.pallet_sequences_next_pallet_sequence_number()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_next_pallet_sequence_number
      BEFORE INSERT
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.pallet_sequences_next_pallet_sequence_number();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER pallet_sequences_next_pallet_sequence_number ON public.pallet_sequences;
      DROP FUNCTION public.pallet_sequences_next_pallet_sequence_number();

      CREATE OR REPLACE FUNCTION public.pallet_sequences_next_pallet_sequence_number()
        RETURNS trigger AS
      $BODY$
        DECLARE
          next_pallet_sequence_number INTEGER;
        BEGIN
          EXECUTE 'SELECT count(id) + 1
          FROM pallet_sequences
          WHERE pallet_id = $1'
          INTO next_pallet_sequence_number
          USING NEW.pallet_id;

          NEW.pallet_sequence_number = next_pallet_sequence_number;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.pallet_sequences_next_pallet_sequence_number()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_next_pallet_sequence_number
      BEFORE INSERT
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.pallet_sequences_next_pallet_sequence_number();
    SQL
  end
end

