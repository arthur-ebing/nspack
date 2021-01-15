Sequel.migration do
  up do
    alter_table(:system_resources) do
      add_column :legacy_messcada, :boolean, default: false
    end
  end

  down do
    alter_table(:system_resources) do
      drop_column :legacy_messcada
    end
  end
end
