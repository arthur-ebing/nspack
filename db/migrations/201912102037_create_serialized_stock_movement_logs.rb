require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:serialized_stock_movement_logs, ignore_index_errors: true) do
      primary_key :id
      foreign_key :location_from_id, :locations, type: :integer, null: false
      foreign_key :location_to_id, :locations, type: :integer, null: false
      Integer :stock_item_id
      String :stock_item_number
      Integer :business_process_id
      Integer :business_process_object_id
      Integer :serialized_stock_type_id
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:serialized_stock_movement_logs,
                   :created_at,
                   function_name: :serialized_stock_movement_logs_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:serialized_stock_movement_logs,
                   :updated_at,
                   function_name: :serialized_stock_movement_logs_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('serialized_stock_movement_logs', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:serialized_stock_movement_logs, :audit_trigger_row)
    drop_trigger(:serialized_stock_movement_logs, :audit_trigger_stm)

    drop_trigger(:serialized_stock_movement_logs, :set_created_at)
    drop_function(:serialized_stock_movement_logs_set_created_at)
    drop_trigger(:serialized_stock_movement_logs, :set_updated_at)
    drop_function(:serialized_stock_movement_logs_set_updated_at)
    drop_table(:serialized_stock_movement_logs)
  end
end
