Sequel.migration do
  up do

    run <<~SQL
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.pallet_sequences;
      DROP FUNCTION public.update_pallet_sequences_phyto_data_from_pseq();
    SQL

    run <<~SQL
      CREATE FUNCTION PUBLIC.update_pallet_sequences_phyto_data_from_pseq()
      RETURNS trigger AS
      $BODY$
      BEGIN
        IF (SELECT exit_ref FROM pallets WHERE id = NEW.pallet_id) IS NULL THEN
          NEW.phyto_data = (SELECT api_result 
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
      BEFORE INSERT OR UPDATE OF puc_id, orchard_id, cultivar_id ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data_from_pseq();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER update_pallet_sequences_phyto_data ON public.pallet_sequences;
      DROP FUNCTION public.update_pallet_sequences_phyto_data_from_pseq();
    SQL

    run <<~SQL
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
  end
end
