require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:inspection_failure_types, ignore_index_errors: true) do
      primary_key :id
      String :failure_type_code, null: false
      String :description

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:inspection_failure_types,
                   :created_at,
                   function_name: :inspection_failure_type_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:inspection_failure_types,
                   :updated_at,
                   function_name: :inspection_failure_type_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:inspection_failure_types, :set_created_at)
    drop_function(:inspection_failure_type_set_created_at)
    drop_trigger(:inspection_failure_types, :set_updated_at)
    drop_function(:inspection_failure_type_set_updated_at)
    drop_table :inspection_failure_types
  end
end
