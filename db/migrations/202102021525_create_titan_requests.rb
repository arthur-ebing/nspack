require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    extension :pg_json
    create_table(:titan_requests, ignore_index_errors: true) do
      primary_key :id
      foreign_key :load_id, :loads, type: :integer
      foreign_key :govt_inspection_sheet_id, :govt_inspection_sheets, type: :integer
      String :request_type, null: false
      Jsonb :request_doc, null: false
      TrueClass :success, default: false
      Jsonb :result_doc
      Integer :inspection_message_id
      Integer :transaction_id
      Integer :request_id
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:titan_requests,
                   :created_at,
                   function_name: :titan_requests_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:titan_requests,
                   :updated_at,
                   function_name: :titan_requests_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:titan_requests, :set_updated_at)
    drop_function(:titan_requests_set_updated_at)
    drop_trigger(:titan_requests, :set_created_at)
    drop_function(:titan_requests_set_created_at)
    drop_table(:titan_requests)
  end
end
