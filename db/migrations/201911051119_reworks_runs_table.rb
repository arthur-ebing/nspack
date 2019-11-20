require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:reworks_runs, ignore_index_errors: true) do
      primary_key :id
      String :user, null: false
      foreign_key :reworks_run_type_id, :reworks_run_types, type: :integer, null: false
      String :remarks
      foreign_key :scrap_reason_id, :scrap_reasons, type: :integer
      column :pallets_selected, 'text[]'
      column :pallets_affected, 'text[]'
      Jsonb :changes_made
      column :pallets_scrapped, 'text[]'
      column :pallets_unscrapped, 'text[]'
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:reworks_runs,
                   :created_at,
                   function_name: :reworks_runs_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:reworks_runs,
                   :updated_at,
                   function_name: :reworks_runs_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('reworks_runs', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:reworks_runs, :audit_trigger_row)
    drop_trigger(:reworks_runs, :audit_trigger_stm)

    drop_trigger(:reworks_runs, :set_created_at)
    drop_function(:reworks_runs_set_created_at)
    drop_trigger(:reworks_runs, :set_updated_at)
    drop_function(:reworks_runs_set_updated_at)
    drop_table(:reworks_runs)
  end
end
