Sequel.migration do
  up do
    alter_table(:cartons) do
      add_index :pallet_sequence_id, name: :cartons_pallet_sequence_id_idx
    end
  end

  down do
    alter_table(:cartons) do
      drop_index :pallet_sequence_id, name: :cartons_pallet_sequence_id_idx
    end
  end
end
