Sequel.migration do
  up do
    # Function and triggers to update pallet verified.
    # on pallet_sequences verified_at update

    alter_table(:pallets) do
      add_column :verified, :boolean, default: false
      add_column :verified_at, DateTime
    end

    run <<~SQL
      UPDATE pallets 
      SET verified_at = sq.verified_at,
          verified = sq.verified
      FROM ( SELECT pallet_id,
               MAX(verified_at) AS verified_at,
               BOOL_AND(verified) AS verified
             FROM pallet_sequences
             GROUP BY pallet_id
            ) sq
      WHERE pallets.id = sq.pallet_id
      AND sq.verified
    SQL

    run <<~SQL
      CREATE FUNCTION public.fn_update_pallets_verified()
        RETURNS trigger AS
      $BODY$
        DECLARE
        BEGIN
          UPDATE pallets 
          SET verified_at = sq.verified_at,
              verified = sq.verified
          FROM ( SELECT pallet_id,
                   MAX(verified_at) AS verified_at,
                   BOOL_AND(verified) AS verified
                 FROM pallet_sequences
                 WHERE pallet_id = NEW.pallet_id
                 GROUP BY pallet_id
                ) sq
          WHERE pallets.id = sq.pallet_id
          AND sq.verified;
          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_update_pallets_verified()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_update_verified_at
      AFTER UPDATE OF verified_at
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_update_pallets_verified();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER pallet_sequences_update_verified_at ON public.pallet_sequences;
      DROP FUNCTION public.fn_update_pallets_verified();
    SQL

    alter_table(:pallets) do
      drop_column :verified
      drop_column :verified_at
    end
  end
end
