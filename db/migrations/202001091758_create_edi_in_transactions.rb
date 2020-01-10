require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:edi_in_transactions, ignore_index_errors: true) do
      primary_key :id
      String :file_name, null: false
      String :flow_type
      TrueClass :complete, default: false
      String :error_message
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:edi_in_transactions,
                   :created_at,
                   function_name: :edi_in_transactions_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:edi_in_transactions,
                   :updated_at,
                   function_name: :edi_in_transactions_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:edi_in_transactions, :set_created_at)
    drop_function(:edi_in_transactions_set_created_at)
    drop_trigger(:edi_in_transactions, :set_updated_at)
    drop_function(:edi_in_transactions_set_updated_at)
    drop_table(:edi_in_transactions)
  end
end
