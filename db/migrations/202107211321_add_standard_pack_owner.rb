Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      drop_column :rmt_container_type_id
      drop_column :rmt_container_material_type_id
      add_foreign_key :rmt_container_material_owner_id, :rmt_container_material_owners, null: true, key: [:id]
    end

    alter_table(:product_setups) do
      drop_column :rmt_container_material_owner_id
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      add_foreign_key :rmt_container_type_id, :rmt_container_types
      add_foreign_key :rmt_container_material_type_id, :rmt_container_material_types
      drop_column :rmt_container_material_owner_id
    end

    alter_table(:product_setups) do
      add_foreign_key :rmt_container_material_owner_id, :rmt_container_material_owners, null: true, key: [:id]
    end
  end
end
