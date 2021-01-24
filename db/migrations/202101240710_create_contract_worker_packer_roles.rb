require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:contract_worker_packer_roles, ignore_index_errors: true) do
      primary_key :id
      String :packer_role, null: false
      TrueClass :default_role, default: false
      TrueClass :part_of_group_incentive_target, default: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:packer_role], name: :contract_worker_packer_roles_unique_code, unique: true
    end

    pgt_created_at(:contract_worker_packer_roles,
                   :created_at,
                   function_name: :pgt_contract_worker_packer_roles_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:contract_worker_packer_roles,
                   :updated_at,
                   function_name: :pgt_contract_worker_packer_roles_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('contract_worker_packer_roles', true, true, '{updated_at}'::text[]);"

    alter_table(:contract_workers) do
      add_foreign_key :packer_role_id, :contract_worker_packer_roles, type: :integer
      add_column :from_external_system, :boolean, default: false
    end
  end

  down do
    alter_table(:contract_workers) do
      drop_foreign_key :packer_role_id
      drop_column :from_external_system
    end

    # Drop logging for this table.
    drop_trigger(:contract_worker_packer_roles, :audit_trigger_row)
    drop_trigger(:contract_worker_packer_roles, :audit_trigger_stm)

    drop_trigger(:contract_worker_packer_roles, :set_created_at)
    drop_function(:pgt_contract_worker_packer_roles_set_created_at)
    drop_trigger(:contract_worker_packer_roles, :set_updated_at)
    drop_function(:pgt_contract_worker_packer_roles_set_updated_at)
    drop_table(:contract_worker_packer_roles)
  end
end
