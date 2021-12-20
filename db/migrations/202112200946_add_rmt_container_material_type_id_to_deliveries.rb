Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_foreign_key :rmt_container_material_type_id, :rmt_container_material_types, key: [:id]
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :rmt_container_material_type_id
    end
  end
end
