Sequel.migration do
  up do
    alter_table(:cultivars) do
      add_column :registered_code, String
    end
  end

  down do
    alter_table(:cultivars) do
      drop_column :registered_code
    end
  end
end

