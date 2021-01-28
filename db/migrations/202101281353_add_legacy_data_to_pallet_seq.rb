Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_column :legacy_data, :jsonb
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_column :legacy_data
    end
  end
end
