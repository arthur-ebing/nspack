require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_container_material_owners, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_container_material_type_id, :rmt_container_material_types, type: :integer, null: false
      foreign_key :rmt_material_owner_party_role_id, :party_roles, type: :integer, null: false

      index [:rmt_container_material_type_id], name: :fki_rmt_container_material_type_id
      index [:rmt_material_owner_party_role_id], name: :fki_party_roles_id
    end

    # pgt_created_at(:rmt_container_material_owners,
    #                :created_at,
    #                function_name: :rmt_container_material_owners_set_created_at,
    #                trigger_name: :set_created_at)
    #
    # pgt_updated_at(:rmt_container_material_owners,
    #                :updated_at,
    #                function_name: :rmt_container_material_owners_set_updated_at,
    #                trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    # run "SELECT audit.audit_table('rmt_container_material_owners', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    # drop_trigger(:rmt_container_material_owners, :audit_trigger_row)
    # drop_trigger(:rmt_container_material_owners, :audit_trigger_stm)
    #
    # drop_trigger(:rmt_container_material_owners, :set_created_at)
    # drop_function(:rmt_container_material_owners_set_created_at)
    # drop_trigger(:rmt_container_material_owners, :set_updated_at)
    # drop_function(:rmt_container_material_owners_set_updated_at)
    drop_table(:rmt_container_material_owners)
  end
end
