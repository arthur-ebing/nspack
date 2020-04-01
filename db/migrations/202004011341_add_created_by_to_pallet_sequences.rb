Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_foreign_key :created_by, :users, type: :integer
      add_foreign_key :verified_by, :users, type: :integer
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_column :created_by
      drop_column :verified_by
    end
  end
end