Sequel.migration do
  up do
    alter_table(:system_resources) do
      add_column :extended_config, :jsonb
    end
  end

  down do
    alter_table(:system_resources) do
      drop_column :extended_config
    end
  end
end
