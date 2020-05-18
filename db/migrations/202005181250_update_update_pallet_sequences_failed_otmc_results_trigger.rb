Sequel.migration do
  up do
    run <<~SQL
      DROP TRIGGER update_pallet_sequences_failed_otmc_results ON public.pallet_sequences;
    SQL

    run <<~SQL
      CREATE FUNCTION public.apply_failed_otmc_results_to_pallet_sequence()
      RETURNS trigger AS
      $BODY$
      BEGIN

        IF (SELECT exit_ref FROM pallets WHERE id = NEW.pallet_id) IS NULL THEN
        NEW.failed_otmc_results = 
          (select
            array_agg(test_type_id order by test_type_id) filter (where test_type_id is not null)
            from vw_orchard_test_results_flat
            where not passed 
            and not classification
            and NEW.puc_id = puc_id
            and NEW.orchard_id = orchard_id
            and NEW.cultivar_id = cultivar_id
            and NEW.packed_tm_group_id = ANY(tm_group_ids)
            group by puc_id, orchard_id, cultivar_id
          );
        END IF; 

        RETURN new;
      END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;

      CREATE TRIGGER apply_failed_otmc_results_to_pallet_sequence
      BEFORE INSERT OR UPDATE OF puc_id, orchard_id, cultivar_id, packed_tm_group_id ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE apply_failed_otmc_results_to_pallet_sequence();
    SQL


  end

  down do
    run <<~SQL
      DROP TRIGGER apply_failed_otmc_results_to_pallet_sequence ON public.pallet_sequences;
      DROP FUNCTION public.apply_failed_otmc_results_to_pallet_sequence();
    SQL

    run <<~SQL
      CREATE TRIGGER update_pallet_sequences_failed_otmc_results
      AFTER INSERT OR UPDATE OF puc_id, orchard_id, cultivar_id, packed_tm_group_id ON pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE update_pallet_sequences_failed_otmc_results();
    SQL
  end
end

