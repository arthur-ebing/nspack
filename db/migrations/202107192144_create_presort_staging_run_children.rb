require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:presort_staging_run_children, ignore_index_errors: true) do
      primary_key :id
      foreign_key :presort_staging_run_id, :presort_staging_runs, type: :integer, null: true
      DateTime :created_at
      DateTime :activated_at
      DateTime :staged_at
      TrueClass :canceled, default: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      TrueClass :editing, default: false
      TrueClass :staged, default: false
      TrueClass :active, default: false
      index [:farm_id, :presort_staging_run_id], name: :presort_staging_run_child_farm_id_unique, unique: true
    end

    pgt_created_at(:presort_staging_run_children,
                   :created_at,
                   function_name: :presort_staging_run_children_set_created_at,
                   trigger_name: :set_created_at)
  end

  down do
    drop_trigger(:presort_staging_run_children, :set_created_at)
    drop_function(:presort_staging_run_children_set_created_at)
    drop_table(:presort_staging_run_children)
  end
end
