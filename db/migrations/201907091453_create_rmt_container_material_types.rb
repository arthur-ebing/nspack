require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_container_material_types, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_container_type_id, :rmt_container_types, type: :integer, null: false
      String :container_material_type_code, null: false
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:container_material_type_code], name: :rmt_container_material_types_unique_code, unique: true
    end

    pgt_created_at(:rmt_container_material_types,
                   :created_at,
                   function_name: :rmt_container_material_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_container_material_types,
                   :updated_at,
                   function_name: :rmt_container_material_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_container_material_types', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:rmt_container_material_types, :audit_trigger_row)
    drop_trigger(:rmt_container_material_types, :audit_trigger_stm)

    drop_trigger(:rmt_container_material_types, :set_created_at)
    drop_function(:rmt_container_material_types_set_created_at)
    drop_trigger(:rmt_container_material_types, :set_updated_at)
    drop_function(:rmt_container_material_types_set_updated_at)
    drop_table(:rmt_container_material_types)
  end
end
