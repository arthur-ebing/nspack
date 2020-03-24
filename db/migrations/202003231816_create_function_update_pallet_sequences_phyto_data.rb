Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION public.update_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET phyto_data = sq.phyto_data
        FROM (SELECT pallet_sequences.id,
                orchards.otmc_results -> 'PHYTODATA' AS phyto_data
              FROM pallet_sequences
              JOIN orchards ON pallet_sequences.orchard_id = orchards.id
              WHERE pallet_sequences.exit_ref IS NULL) AS sq
        WHERE ps.id = sq.id;
        RETURN new; 
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER INSERT
      ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data();

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER UPDATE OR DELETE
      ON orchards
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data();
    SQL

  end

  down do
    run <<~SQL
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.pallet_sequences;
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.orchard_test_results;
      DROP FUNCTION public.update_pallet_sequences_phyto_data();
    SQL
  end
end

