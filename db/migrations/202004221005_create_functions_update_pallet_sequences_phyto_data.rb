Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION public.insert_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET phyto_data = otr.api_result

        FROM orchard_test_results otr
        JOIN orchard_test_types ott ON otr.orchard_test_type_id = ott.id

        WHERE ps.id = NEW.id
          AND otr.puc_id = NEW.puc_id
          AND otr.orchard_id = NEW.orchard_id
          AND otr.cultivar_id = NEW.cultivar_id
          AND ott.test_type_code = 'PHYTODATA'
          AND ps.exit_ref IS NULL;
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
        UPDATE pallet_sequences ps
        SET phyto_data = otr.api_result

        FROM orchard_test_results otr
        JOIN orchard_test_types ott ON otr.orchard_test_type_id = ott.id

        WHERE ps.puc_id = NEW.puc_id
          AND ps.orchard_id = NEW.orchard_id
          AND ps.cultivar_id = NEW.cultivar_id
          AND otr.puc_id = NEW.puc_id
          AND otr.orchard_id = NEW.orchard_id
          AND otr.cultivar_id = NEW.cultivar_id
          AND ott.test_type_code = 'PHYTODATA'
          AND ps.exit_ref IS NULL;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER UPDATE OF api_result
      ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data();
    SQL

    run <<~SQL
      CREATE FUNCTION public.delete_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
        SET phyto_data = NULL

        FROM orchard_test_results otr
        JOIN orchard_test_types ott ON otr.orchard_test_type_id = ott.id

        WHERE ps.puc_id = old.puc_id
          AND ps.orchard_id = old.orchard_id
          AND ps.cultivar_id = old.cultivar_id
          AND otr.puc_id = old.puc_id
          AND otr.orchard_id = old.orchard_id
          AND otr.cultivar_id = old.cultivar_id
          AND ott.test_type_code = 'PHYTODATA'
          AND ps.exit_ref IS NULL;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER delete_pallet_sequences_phyto_data
      AFTER DELETE
      ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE delete_pallet_sequences_phyto_data();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER delete_pallet_sequences_phyto_data ON public.orchard_test_results;
      DROP FUNCTION public.delete_pallet_sequences_phyto_data();
    SQL

    run <<~SQL
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.orchard_test_results;
      DROP FUNCTION public.update_pallet_sequences_phyto_data();
    SQL

    run <<~SQL
      DROP TRIGGER insert_pallet_sequences_phyto_data ON public.pallet_sequences;
      DROP FUNCTION public.insert_pallet_sequences_phyto_data();
    SQL
  end
end
