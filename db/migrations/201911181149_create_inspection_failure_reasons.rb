require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:inspection_failure_reasons, ignore_index_errors: true) do
      primary_key :id
      foreign_key :inspection_failure_type_id, :inspection_failure_types, type: :integer, null: false
      String :failure_reason, null: false
      String :description
      TrueClass :main_factor, default: false
      TrueClass :secondary_factor, default: false


      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:inspection_failure_reasons,
                   :created_at,
                   function_name: :inspection_failure_reason_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:inspection_failure_reasons,
                   :updated_at,
                   function_name: :inspection_failure_reason_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:inspection_failure_reasons, :set_created_at)
    drop_function(:inspection_failure_reason_set_created_at)
    drop_trigger(:inspection_failure_reasons, :set_updated_at)
    drop_function(:inspection_failure_reason_set_updated_at)
    drop_table :inspection_failure_reasons
  end
end
