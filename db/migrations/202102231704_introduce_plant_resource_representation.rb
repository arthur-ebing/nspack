Sequel.migration do
  up do
    alter_table(:plant_resource_types) do
      add_foreign_key :represents_plant_resource_type_id, :plant_resource_types, foreign_key_constraint_name: :plant_resource_type_representation_fk
    end

    alter_table(:plant_resources) do
      add_foreign_key :represents_plant_resource_id, :plant_resources, foreign_key_constraint_name: :plant_resource_representation_fk
    end
  end

  down do
    alter_table(:plant_resource_types) do
      drop_foreign_key :represents_plant_resource_type_id
    end

    alter_table(:plant_resources) do
      drop_foreign_key :represents_plant_resource_id
    end
  end
end
