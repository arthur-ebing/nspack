Sequel.migration do
  up do
    run <<~SQL
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.orchards;
      DROP FUNCTION public.update_pallet_sequences_phyto_data();
    SQL

    run <<~SQL
      DROP TRIGGER insert_pallet_sequences_phyto_data ON public.pallet_sequences;
      DROP FUNCTION public.insert_pallet_sequences_phyto_data();
    SQL
  end

  down do
    run <<~SQL
      CREATE FUNCTION public.insert_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET phyto_data = (SELECT orchards.otmc_results -> 'PHYTODATA'
                          FROM orchards
                          WHERE orchards.id = pallet_sequences.orchard_id)
        WHERE pallet_sequences.id = NEW.id
          AND pallet_sequences.exit_ref IS NULL;
        RETURN new; 
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER insert_pallet_sequences_phyto_data
      AFTER INSERT
      ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE insert_pallet_sequences_phyto_data();
    SQL

    run <<~SQL
      CREATE FUNCTION public.update_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET phyto_data = (SELECT orchards.otmc_results -> 'PHYTODATA'
                          FROM orchards
                          WHERE orchards.id = pallet_sequences.orchard_id)
        WHERE pallet_sequences.orchard_id = NEW.id
          AND pallet_sequences.exit_ref IS NULL;
        RETURN new; 
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER UPDATE OF otmc_results
      ON orchards
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data();
    SQL

  end
end
