require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:stock_types, ignore_index_errors: true) do
      primary_key :id
      String :stock_type_code
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:stock_type_code], name: :stock_types_unique_code, unique: true
    end

    pgt_created_at(:stock_types,
                   :created_at,
                   function_name: :stock_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:stock_types,
                   :updated_at,
                   function_name: :stock_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('stock_types', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:stock_types, :audit_trigger_row)
    drop_trigger(:stock_types, :audit_trigger_stm)

    drop_trigger(:stock_types, :set_created_at)
    drop_function(:stock_types_set_created_at)
    drop_trigger(:stock_types, :set_updated_at)
    drop_function(:stock_types_set_updated_at)
    drop_table(:stock_types)
  end
end
