Sequel.migration do
  up do
    alter_table(:pallets) do
      add_index :load_id, name: :pallets_load_id_idx
    end
  end

  down do
    alter_table(:pallets) do
      drop_index :load_id, name: :pallets_load_id_idx
    end
  end
end
