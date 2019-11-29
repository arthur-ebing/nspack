require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
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
  end

  down do
    drop_trigger(:govt_inspection_pallet_api_results, :set_created_at)
    drop_function(:govt_inspection_pallet_api_result_set_created_at)
    drop_trigger(:govt_inspection_pallet_api_results, :set_updated_at)
    drop_function(:govt_inspection_pallet_api_result_set_updated_at)
    drop_table :govt_inspection_pallet_api_results
  end
end
