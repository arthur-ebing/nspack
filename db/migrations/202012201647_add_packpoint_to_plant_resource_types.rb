Sequel.migration do
  up do
    alter_table(:plant_resource_types) do
      add_column :packpoint, TrueClass, default: false
    end

    run <<~SQL
      UPDATE plant_resource_types SET packpoint = true
      WHERE plant_resource_type_code = 'DROP_STATION';
    SQL
  end

  down do
    alter_table(:plant_resource_types) do
      drop_column :packpoint
    end
  end
end
