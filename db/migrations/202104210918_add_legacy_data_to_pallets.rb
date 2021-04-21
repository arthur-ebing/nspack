Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :legacy_data, :jsonb
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :legacy_data
    end
  end
end
