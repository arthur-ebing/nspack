require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:presort_staging_runs, ignore_index_errors: true) do
      primary_key :id
      DateTime :created_at
      DateTime :uncompleted_at
      DateTime :staged_at
      TrueClass :completed, default: false
      Integer :presort_unit_plant_resource_id
      foreign_key :supplier_id, :suppliers, type: :integer, null: true
      DateTime :completed_at
      TrueClass :canceled, default: false
      DateTime :canceled_at
      foreign_key :cultivar_id, :cultivars, type: :integer, null: false
      foreign_key :rmt_class_id, :rmt_classes, type: :integer, null: false
      foreign_key :rmt_size_id, :rmt_sizes, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
      TrueClass :editing, default: false
      TrueClass :staged, default: false
      TrueClass :active, default: true
      Jsonb :legacy_data
    end

    pgt_created_at(:presort_staging_runs,
                   :created_at,
                   function_name: :presort_staging_runs_set_created_at,
                   trigger_name: :set_created_at)
  end

  down do
    drop_trigger(:presort_staging_runs, :set_created_at)
    drop_function(:presort_staging_runs_set_created_at)
    drop_table(:presort_staging_runs)
  end
end
