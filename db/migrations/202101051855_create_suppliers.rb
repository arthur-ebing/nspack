require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:supplier_groups, ignore_index_errors: true) do
      primary_key :id
      String :supplier_group_code, size: 255, null: false
      String :description, size: 255
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:supplier_groups,
                   :created_at,
                   function_name: :supplier_groups_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:supplier_groups,
                   :updated_at,
                   function_name: :supplier_groups_set_updated_at,
                   trigger_name: :set_updated_at)

    create_table(:suppliers, ignore_index_errors: true) do
      primary_key :id
      foreign_key :supplier_party_role_id, :party_roles, type: :integer, null: false
      column :supplier_group_ids, 'int[]'
      column :farm_ids, 'int[]'
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:suppliers,
                   :created_at,
                   function_name: :suppliers_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:suppliers,
                   :updated_at,
                   function_name: :suppliers_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('suppliers', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:suppliers, :audit_trigger_row)
    drop_trigger(:suppliers, :audit_trigger_stm)

    drop_trigger(:suppliers, :set_created_at)
    drop_function(:suppliers_set_created_at)
    drop_trigger(:suppliers, :set_updated_at)
    drop_function(:suppliers_set_updated_at)
    drop_table(:suppliers)

    drop_trigger(:supplier_groups, :set_created_at)
    drop_function(:supplier_groups_set_created_at)
    drop_trigger(:supplier_groups, :set_updated_at)
    drop_function(:supplier_groups_set_updated_at)
    drop_table(:supplier_groups)
  end
end
