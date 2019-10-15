Sequel.migration do
  up do
    alter_table(:plant_resources) do
      add_foreign_key :location_id, :locations
      add_column :resource_properties, :jsonb
    end
  end

  down do
    alter_table(:plant_resources) do
      drop_foreign_key :location_id
      drop_column :resource_properties
    end
  end
end
