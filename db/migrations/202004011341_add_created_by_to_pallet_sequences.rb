Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_column :created_by, String
      add_column :verified_by, String
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_column :created_by
      drop_column :verified_by
    end
  end
end