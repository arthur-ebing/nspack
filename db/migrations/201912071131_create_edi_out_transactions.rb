require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:edi_out_transactions, ignore_index_errors: true) do
      primary_key :id
      String :flow_type, null: false
      String :org_code, null: false
      String :hub_address, null: false
      String :user_name, null: false
      TrueClass :complete, default: false
      String :edi_out_filename
      Integer :record_id
      String :error_message
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:edi_out_transactions,
                   :created_at,
                   function_name: :edi_out_transactions_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:edi_out_transactions,
                   :updated_at,
                   function_name: :edi_out_transactions_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('edi_out_transactions', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:edi_out_transactions, :audit_trigger_row)
    drop_trigger(:edi_out_transactions, :audit_trigger_stm)

    drop_trigger(:edi_out_transactions, :set_created_at)
    drop_function(:edi_out_transactions_set_created_at)
    drop_trigger(:edi_out_transactions, :set_updated_at)
    drop_function(:edi_out_transactions_set_updated_at)
    drop_table(:edi_out_transactions)
  end
end
