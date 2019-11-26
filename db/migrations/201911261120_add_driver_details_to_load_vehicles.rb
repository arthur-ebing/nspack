Sequel.migration do
  up do
    alter_table(:load_vehicles) do
      add_column :driver_name, String
      add_column :driver_cell_number, String
    end
  end

  down do
    alter_table(:load_vehicles) do
      drop_column :driver_name
      drop_column :driver_cell_number
    end
  end
end
