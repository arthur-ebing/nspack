require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:presort_staging_runs, ignore_index_errors: true) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      DateTime :activated_at
      DateTime :setup_uncompleted_at
      DateTime :staged_at
      TrueClass :setup_completed, default: false
      foreign_key :supplier_id, :suppliers, type: :integer, null: false
      foreign_key :presort_unit_plant_resource_id, :plant_resources, type: :integer, null: false
      DateTime :setup_completed_at
      TrueClass :canceled, default: false
      DateTime :canceled_at
      foreign_key :cultivar_id, :cultivars, type: :integer, null: false
      foreign_key :rmt_class_id, :rmt_classes, type: :integer, null: false
      foreign_key :rmt_size_id, :rmt_sizes, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
      TrueClass :editing, default: false
      TrueClass :staged, default: false
      TrueClass :running, default: false
      Jsonb :legacy_data
    end

    pgt_created_at(:presort_staging_runs,
                   :created_at,
                   function_name: :presort_staging_runs_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:presort_staging_runs,
                   :updated_at,
                   function_name: :presort_staging_runs_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('presort_staging_runs', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:presort_staging_runs, :audit_trigger_row)
    drop_trigger(:presort_staging_runs, :audit_trigger_stm)

    drop_trigger(:presort_staging_runs, :set_created_at)
    drop_function(:presort_staging_runs_set_created_at)
    drop_trigger(:presort_staging_runs, :set_updated_at)
    drop_function(:presort_staging_runs_set_updated_at)
    drop_table(:presort_staging_runs)
  end
end
