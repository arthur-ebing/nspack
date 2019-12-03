require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:inspectors, ignore_index_errors: true) do
      primary_key :id
      foreign_key :inspector_party_role_id, :party_roles, type: :integer, null: false
      String :tablet_ip_address
      Integer :tablet_port_number

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:inspectors,
                   :created_at,
                   function_name: :inspector_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:inspectors,
                   :updated_at,
                   function_name: :inspector_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:inspectors, :set_created_at)
    drop_function(:inspector_set_created_at)
    drop_trigger(:inspectors, :set_updated_at)
    drop_function(:inspector_set_updated_at)
    drop_table :inspectors
  end
end
