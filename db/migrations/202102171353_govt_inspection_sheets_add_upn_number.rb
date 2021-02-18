Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :upn, String
      drop_column :govt_inspection_api_result_id
    end

    drop_trigger(:govt_inspection_pallet_api_results, :set_created_at)
    drop_function(:govt_inspection_pallet_api_result_set_created_at)
    drop_trigger(:govt_inspection_pallet_api_results, :set_updated_at)
    drop_function(:govt_inspection_pallet_api_result_set_updated_at)
    drop_table :govt_inspection_pallet_api_results

    drop_trigger(:govt_inspection_api_results, :set_created_at)
    drop_function(:govt_inspection_api_result_set_created_at)
    drop_trigger(:govt_inspection_api_results, :set_updated_at)
    drop_function(:govt_inspection_api_result_set_updated_at)
    drop_table :govt_inspection_api_results
  end

  down do
    create_table(:govt_inspection_api_results, ignore_index_errors: true) do
      primary_key :id
      foreign_key :govt_inspection_sheet_id, :govt_inspection_sheets, type: :integer

      Jsonb :govt_inspection_request_doc
      Jsonb :govt_inspection_result_doc

      TrueClass :results_requested, default: false
      DateTime :results_requested_at

      TrueClass :results_received, default: false
      DateTime :results_received_at

      String :upn_number
      String :remarks

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:govt_inspection_api_results,
                   :created_at,
                   function_name: :govt_inspection_api_result_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:govt_inspection_api_results,
                   :updated_at,
                   function_name: :govt_inspection_api_result_set_updated_at,
                   trigger_name: :set_updated_at)

    create_table(:govt_inspection_pallet_api_results, ignore_index_errors: true) do
      primary_key :id
      TrueClass :passed, default: false

      Jsonb :failure_reasons

      foreign_key :govt_inspection_pallet_id, :govt_inspection_pallets, type: :integer
      foreign_key :govt_inspection_api_result_id, :govt_inspection_api_results, type: :integer

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:govt_inspection_pallet_api_results,
                   :created_at,
                   function_name: :govt_inspection_pallet_api_result_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:govt_inspection_pallet_api_results,
                   :updated_at,
                   function_name: :govt_inspection_pallet_api_result_set_updated_at,
                   trigger_name: :set_updated_at)

    alter_table(:govt_inspection_sheets) do
      add_foreign_key :govt_inspection_api_result_id, :govt_inspection_api_results, key: [:id], null: true
      drop_column :upn
    end
  end
end
