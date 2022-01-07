Sequel.migration do
  up do
    # Change build status trigger (which updates pallets) to run after insert/update of sequence.
    run <<~SQL
      DROP TRIGGER pallet_sequences_update_pallet_build_status ON public.pallet_sequences;


      CREATE TRIGGER pallet_sequences_update_pallet_build_status
      AFTER INSERT OR UPDATE OF cartons_per_pallet_id, carton_quantity
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_seq_build_status_calc();
    SQL
  end

  down do
    # Reset trigger to take place before insert/update.
    run <<~SQL
      DROP TRIGGER pallet_sequences_update_pallet_build_status ON public.pallet_sequences;


      CREATE TRIGGER pallet_sequences_update_pallet_build_status
      BEFORE INSERT OR UPDATE OF cartons_per_pallet_id, carton_quantity
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_pallet_seq_build_status_calc();
    SQL
  end
end
