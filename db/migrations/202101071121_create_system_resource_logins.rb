require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:system_resource_logins, ignore_index_errors: true) do
      primary_key :id
      foreign_key :system_resource_id, :system_resources, null: false
      String :card_reader, null: false
      foreign_key :contract_worker_id, :contract_workers
      String :identifier
      DateTime :login_at
      DateTime :last_logout_at
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:system_resource_id, :card_reader], name: :system_resource_logins_unique_code, unique: true
    end

    pgt_created_at(:system_resource_logins,
                   :created_at,
                   function_name: :pgt_system_resource_logins_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:system_resource_logins,
                   :updated_at,
                   function_name: :pgt_system_resource_logins_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('system_resource_logins', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:system_resource_logins, :audit_trigger_row)
    drop_trigger(:system_resource_logins, :audit_trigger_stm)

    drop_trigger(:system_resource_logins, :set_created_at)
    drop_function(:pgt_system_resource_logins_set_created_at)
    drop_trigger(:system_resource_logins, :set_updated_at)
    drop_function(:pgt_system_resource_logins_set_updated_at)
    drop_table(:system_resource_logins)
  end
end
