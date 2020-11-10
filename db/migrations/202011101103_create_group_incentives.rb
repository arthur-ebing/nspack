require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:group_incentives, ignore_index_errors: true) do
      primary_key :id
      foreign_key :system_resource_id, :system_resources, null: false
      column :contract_worker_ids, 'int[]'
      TrueClass :active, default: true
      DateTime :created_at, null: false

      index [:system_resource_id], name: :fki_group_incentives_system_resources
    end

    pgt_created_at(:group_incentives,
                   :created_at,
                   function_name: :pgt_group_incentives_set_created_at,
                   trigger_name: :set_created_at)

    # Log changes to this table.
    run "SELECT audit.audit_table('group_incentives', true, true);"

    alter_table(:system_resources) do
      add_column :group_incentive, TrueClass, default: false
    end
  end

  down do
    alter_table(:system_resources) do
      drop_column :group_incentive
    end

    # Drop logging for this table.
    drop_trigger(:group_incentives, :audit_trigger_row)
    drop_trigger(:group_incentives, :audit_trigger_stm)

    drop_trigger(:group_incentives, :set_created_at)
    drop_function(:pgt_group_incentives_set_created_at)
    drop_table(:group_incentives)
  end
end
