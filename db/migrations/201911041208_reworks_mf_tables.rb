require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:reworks_run_types, ignore_index_errors: true) do
      primary_key :id
      String :run_type, size: 255, null: false
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:run_type], name: :reworks_run_types_unique_code, unique: true
    end

    pgt_created_at(:reworks_run_types,
                   :created_at,
                   function_name: :reworks_run_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:reworks_run_types,
                   :updated_at,
                   function_name: :reworks_run_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('reworks_run_types', true, true, '{updated_at}'::text[]);"

    create_table(:scrap_reasons, ignore_index_errors: true) do
      primary_key :id
      String :scrap_reason, size: 255, null: false
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:scrap_reason], name: :scrap_reasons_unique_code, unique: true
    end

    pgt_created_at(:scrap_reasons,
                   :created_at,
                   function_name: :scrap_reasons_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:scrap_reasons,
                   :updated_at,
                   function_name: :scrap_reasons_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('scrap_reasons', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:reworks_run_types, :audit_trigger_row)
    drop_trigger(:reworks_run_types, :audit_trigger_stm)

    drop_trigger(:reworks_run_types, :set_created_at)
    drop_function(:reworks_run_types_set_created_at)
    drop_trigger(:reworks_run_types, :set_updated_at)
    drop_function(:reworks_run_types_set_updated_at)
    drop_table(:reworks_run_types)

    drop_trigger(:scrap_reasons, :audit_trigger_row)
    drop_trigger(:scrap_reasons, :audit_trigger_stm)

    drop_trigger(:scrap_reasons, :set_created_at)
    drop_function(:scrap_reasons_set_created_at)
    drop_trigger(:scrap_reasons, :set_updated_at)
    drop_function(:scrap_reasons_set_updated_at)
    drop_table(:scrap_reasons)
  end
end
