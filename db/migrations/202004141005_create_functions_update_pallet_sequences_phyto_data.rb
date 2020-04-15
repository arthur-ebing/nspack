Sequel.migration do
  up do
    run <<~SQL
      CREATE FUNCTION public.insert_pallet_sequences_phyto_data()
      RETURNS trigger AS
      $BODY$
      BEGIN
        UPDATE pallet_sequences ps
-- Could this query ever return more than one row?
-- - perhaps it should include LIMIT 1...
-- - would then apply to the functions below too.
        SET phyto_data = (SELECT DISTINCT vw.classification
                          FROM vw_orchard_test_results_flat vw
                          WHERE ps.puc_id = ANY(vw.puc_ids)
                            AND ps.orchard_id = ANY(vw.orchard_ids)
                            AND ps.cultivar_id = ANY(vw.cultivar_ids)
                            AND vw.test_type_code = 'PHYTODATA')
        WHERE ps.id = NEW.id
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
        SET phyto_data = (SELECT DISTINCT vw.classification
                          FROM vw_orchard_test_results_flat vw
                          WHERE NEW.puc_id = ANY(vw.puc_ids)
                            AND NEW.orchard_id = ANY(vw.orchard_ids)
                            AND NEW.cultivar_id = ANY(vw.cultivar_ids)
                            AND vw.test_type_code = 'PHYTODATA')
        WHERE ps.puc_id = NEW.puc_id
          AND ps.orchard_id = NEW.orchard_id
          AND ps.cultivar_id = NEW.cultivar_id
          AND ps.exit_ref IS NULL;
        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER update_pallet_sequences_phyto_data
      AFTER UPDATE OF classification
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
        SET phyto_data = (SELECT DISTINCT vw.classification
                          FROM vw_orchard_test_results_flat vw
                          WHERE NEW.puc_id = ANY(vw.puc_ids)
                            AND NEW.orchard_id = ANY(vw.orchard_ids)
                            AND NEW.cultivar_id = ANY(vw.cultivar_ids)
                            AND vw.test_type_code = 'PHYTODATA')
        WHERE ps.puc_id = OLD.puc_id
          AND ps.orchard_id = OLD.orchard_id
          AND ps.cultivar_id = OLD.cultivar_id
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
