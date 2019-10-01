require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:production_runs, ignore_index_errors: true) do
      primary_key :id
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :puc_id, :pucs, type: :integer, null: false
      foreign_key :packhouse_resource_id, :plant_resources, type: :integer, null: false
      foreign_key :production_line_id, :plant_resources, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :product_setup_template_id, :product_setup_templates, type: :integer
      foreign_key :cloned_from_run_id, :production_runs, type: :integer
      String :active_run_stage
      DateTime :started_at
      DateTime :closed_at
      DateTime :re_executed_at
      DateTime :completed_at
      TrueClass :allow_cultivar_mixing, default: false
      TrueClass :allow_orchard_mixing, default: false
      TrueClass :reconfiguring, default: false
      TrueClass :closed, default: false
      TrueClass :setup_complete, default: false
      TrueClass :running, default: false
      TrueClass :completed, default: false
      TrueClass :tipping, default: false
      TrueClass :labeling, default: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:production_runs,
                   :created_at,
                   function_name: :production_runs_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:production_runs,
                   :updated_at,
                   function_name: :production_runs_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('production_runs', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:production_runs, :audit_trigger_row)
    drop_trigger(:production_runs, :audit_trigger_stm)

    drop_trigger(:production_runs, :set_created_at)
    drop_function(:production_runs_set_created_at)
    drop_trigger(:production_runs, :set_updated_at)
    drop_function(:production_runs_set_updated_at)
    drop_table(:production_runs)
  end
end
