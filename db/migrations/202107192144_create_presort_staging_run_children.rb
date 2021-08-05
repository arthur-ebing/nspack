require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:presort_staging_run_children, ignore_index_errors: true) do
      primary_key :id
      foreign_key :presort_staging_run_id, :presort_staging_runs, type: :integer, null: false
      DateTime :created_at
      DateTime :updated_at
      DateTime :activated_at
      DateTime :staged_at
      TrueClass :canceled, default: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      TrueClass :editing, default: false
      TrueClass :staged, default: false
      TrueClass :running, default: false
      index [:farm_id, :presort_staging_run_id], name: :presort_staging_run_child_farm_id_unique, unique: true
    end

    pgt_created_at(:presort_staging_run_children,
                   :created_at,
                   function_name: :presort_staging_run_children_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:presort_staging_run_children,
                   :updated_at,
                   function_name: :presort_staging_run_children_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('presort_staging_run_children', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:presort_staging_run_children, :audit_trigger_row)
    drop_trigger(:presort_staging_run_children, :audit_trigger_stm)

    drop_trigger(:presort_staging_run_children, :set_created_at)
    drop_function(:presort_staging_run_children_set_created_at)
    drop_trigger(:presort_staging_run_children, :set_updated_at)
    drop_function(:presort_staging_run_children_set_updated_at)
    drop_table(:presort_staging_run_children)
  end
end
