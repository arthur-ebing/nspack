require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:product_resource_allocations, ignore_index_errors: true) do
      primary_key :id
      foreign_key :production_run_id, :production_runs, type: :integer, null: false
      foreign_key :plant_resource_id, :plant_resources, type: :integer, null: false
      foreign_key :product_setup_id, :product_setups, type: :integer
      foreign_key :label_template_id, :label_templates, type: :integer
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:production_run_id]
      index [:plant_resource_id]
      unique [:production_run_id, :plant_resource_id]
    end

    pgt_created_at(:product_resource_allocations,
                   :created_at,
                   function_name: :product_resource_allocations_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:product_resource_allocations,
                   :updated_at,
                   function_name: :product_resource_allocations_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('product_resource_allocations', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:product_resource_allocations, :audit_trigger_row)
    drop_trigger(:product_resource_allocations, :audit_trigger_stm)

    drop_trigger(:product_resource_allocations, :set_created_at)
    drop_function(:product_resource_allocations_set_created_at)
    drop_trigger(:product_resource_allocations, :set_updated_at)
    drop_function(:product_resource_allocations_set_updated_at)
    drop_table(:product_resource_allocations)
  end
end
