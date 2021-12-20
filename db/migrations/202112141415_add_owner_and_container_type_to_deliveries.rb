Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_foreign_key :rmt_material_owner_party_role_id, :party_roles, key: [:id]
      add_foreign_key :rmt_container_type_id, :rmt_container_types, key: [:id]
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :rmt_material_owner_party_role_id
      drop_column :rmt_container_type_id
    end
  end
end
