Sequel.migration do
  up do
    alter_table(:load_vehicles) do
      drop_column :cooling_type
      add_index [:load_id], name: :load_vehicles_load_id_pkey, unique: true
    end
  end

  down do
    alter_table(:load_vehicles) do
      drop_index :load_id, name: :load_vehicles_load_id_pkey
      add_column :cooling_type, String
    end
  end
end
