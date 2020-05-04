Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION PUBLIC.update_pallet_sequences_phyto_data_from_test()
      RETURNS trigger AS
      $BODY$
      DECLARE
        p_test_type_code text;
      BEGIN
        p_test_type_code = (SELECT api_attribute
                           FROM orchard_test_results 
                           JOIN orchard_test_types ON orchard_test_results.orchard_test_type_id = orchard_test_types.id
                           WHERE orchard_test_results.id = NEW.id);
        IF (p_test_type_code = 'phytoData') THEN
          UPDATE pallet_sequences
          SET phyto_data = NEW.api_result
          WHERE id IN (SELECT ps.id FROM pallet_sequences ps JOIN pallets p ON p.id = ps.pallet_id
                        WHERE ps.puc_id = NEW.puc_id
                          AND ps.orchard_id = NEW.orchard_id
                          AND ps.cultivar_id = NEW.cultivar_id
                          AND p.exit_ref IS NULL
                          AND ps.phyto_data IS DISTINCT FROM NEW.api_result);
        END IF;
        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
      
      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER INSERT OR UPDATE ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data_from_test();
      
      
      CREATE FUNCTION PUBLIC.update_pallet_sequences_phyto_data_from_pseq()
      RETURNS trigger AS
      $BODY$
      BEGIN
        IF (SELECT p.exit_ref IS NULL FROM pallet_sequences ps JOIN pallets p ON ps.pallet_id = p.id WHERE ps.id = NEW.id) THEN
          UPDATE pallet_sequences
          SET phyto_data = (SELECT api_result 
                            FROM orchard_test_results otr
                            JOIN orchard_test_types ott ON otr.orchard_test_type_id = ott.id
                            WHERE api_attribute = 'phytoData'
                              AND otr.puc_id = NEW.puc_id
                              AND otr.orchard_id = NEW.orchard_id
                              AND otr.cultivar_id = NEW.cultivar_id);
        END IF;
        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
      
      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER INSERT OR UPDATE OF puc_id, orchard_id, cultivar_id ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data_from_pseq();
    SQL

    run <<~SQL
      CREATE FUNCTION public.delete_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        IF EXISTS (SELECT 1 FROM orchard_test_types WHERE api_attribute = 'phytoData' AND id = OLD.orchard_test_type_id) THEN
          UPDATE pallet_sequences ps
          SET phyto_data = NULL
          FROM pallets p 
  
          WHERE p.id = ps.pallet_id
            AND ps.puc_id = old.puc_id
            AND ps.orchard_id = old.orchard_id
            AND ps.cultivar_id = old.cultivar_id
            AND p.exit_ref IS NULL;
        END IF;
      RETURN NULL;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER delete_pallet_sequences_phyto_data
      AFTER DELETE ON orchard_test_results
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
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.pallet_sequences;
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.orchard_test_results;
      DROP FUNCTION public.update_pallet_sequences_phyto_data_from_pseq();
      DROP FUNCTION public.update_pallet_sequences_phyto_data_from_test();
    SQL
  end
end
