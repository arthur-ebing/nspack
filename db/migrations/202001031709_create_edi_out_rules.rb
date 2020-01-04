require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:edi_out_rules, ignore_index_errors: true) do
      primary_key :id
      String :flow_type, null: false
      foreign_key :depot_id, :depots, type: :integer
      foreign_key :party_role_id, :party_roles, type: :integer
      String :hub_address, null: false
      column :directory_keys, 'text[]', null: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:edi_out_rules,
                   :created_at,
                   function_name: :edi_out_rules_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:edi_out_rules,
                   :updated_at,
                   function_name: :edi_out_rules_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('edi_out_rules', true, true, '{updated_at}'::text[]);"

    alter_table(:edi_out_transactions) do
      add_foreign_key :party_role_id, :party_roles, type: :integer
      add_foreign_key :edi_out_rule_id, :edi_out_rules, type: :integer
    end
  end

  down do
    alter_table(:edi_out_transactions) do
      drop_foreign_key :party_role_id
      drop_foreign_key :edi_out_rule_id
    end

    # Drop logging for this table.
    drop_trigger(:edi_out_rules, :audit_trigger_row)
    drop_trigger(:edi_out_rules, :audit_trigger_stm)

    drop_trigger(:edi_out_rules, :set_created_at)
    drop_function(:edi_out_rules_set_created_at)
    drop_trigger(:edi_out_rules, :set_updated_at)
    drop_function(:edi_out_rules_set_updated_at)
    drop_table(:edi_out_rules)
  end
end
