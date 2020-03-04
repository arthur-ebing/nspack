Sequel.migration do
  up do
    alter_table(:locations) do
      add_column :units_in_location, Integer, default: 0
    end
  end

  down do
    alter_table(:locations) do
      drop_column :units_in_location
    end
  end
end
