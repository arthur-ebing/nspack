Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION public.update_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences
        SET phyto_data = sq.new_phyto_data
        FROM (SELECT
                  ps.id,
                  ps.phyto_data,
                  otr.api_result AS new_phyto_data
              FROM orchard_test_results otr
              JOIN orchard_test_types ott ON otr.orchard_test_type_id = ott.id
              JOIN pallet_sequences ps ON ps.puc_id = otr.puc_id
               AND ps.orchard_id = otr.orchard_id
               AND ps.cultivar_id = otr.cultivar_id
              JOIN pallets p ON p.id = ps.pallet_id
              
              WHERE ott.test_type_code = 'PHYTODATA'
                AND p.exit_ref IS NULL
              GROUP BY
                  ps.id,
                  otr.api_result) sq

        WHERE pallet_sequences.id = sq.id
          AND pallet_sequences.phyto_data IS DISTINCT FROM sq.new_phyto_data;

        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER INSERT OR UPDATE ON orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data();

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER INSERT OR UPDATE OF puc_id, orchard_id, cultivar_id, packed_tm_group_id ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_phyto_data();
    SQL

    run <<~SQL
      CREATE FUNCTION public.delete_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        IF EXISTS (SELECT 1 FROM orchard_test_types WHERE test_type_code = 'PHYTODATA' AND id = OLD.orchard_test_type_id) THEN
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
      DROP FUNCTION public.update_pallet_sequences_phyto_data();
    SQL
  end
end
