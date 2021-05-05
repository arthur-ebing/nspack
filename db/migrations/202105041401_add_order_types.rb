require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:order_types, ignore_index_errors: true) do
      primary_key :id
      String :order_type, null: false
      String :description

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      unique :order_type
    end

    pgt_created_at(:order_types,
                   :created_at,
                   function_name: :order_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:order_types,
                   :updated_at,
                   function_name: :order_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('order_types', true, true, '{updated_at}'::text[]);"
    run "INSERT INTO order_types (order_type) values ('SALES_ORDER')"
  end

  down do
    drop_trigger(:order_types, :audit_trigger_row)
    drop_trigger(:order_types, :audit_trigger_stm)

    drop_trigger(:order_types, :set_created_at)
    drop_function(:order_types_set_created_at)
    drop_trigger(:order_types, :set_updated_at)
    drop_function(:order_types_set_updated_at)
    drop_table :order_types
  end
end
