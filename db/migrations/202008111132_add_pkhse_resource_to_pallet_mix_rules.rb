Sequel.migration do
  up do
    alter_table(:pallet_mix_rules) do
      add_foreign_key :packhouse_plant_resource_id, :plant_resources, type: :integer
    end
  end

  down do
    alter_table(:pallet_mix_rules) do
      drop_column :packhouse_plant_resource_id
    end
  end
end
