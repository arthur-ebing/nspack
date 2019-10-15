require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_container_material_owners, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_container_material_type_id, :rmt_container_material_types, type: :integer, null: false
      foreign_key :rmt_material_owner_party_role_id, :party_roles, type: :integer, null: false

      index [:rmt_container_material_type_id, :rmt_material_owner_party_role_id], name: :fki_rmt_container_material_type_party_roles
    end
  end

  down do
    drop_table(:rmt_container_material_owners)
  end
end
