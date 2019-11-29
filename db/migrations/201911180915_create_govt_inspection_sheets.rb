require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:govt_inspection_sheets, ignore_index_errors: true) do
      primary_key :id
      foreign_key :inspector_id, :inspectors, type: :integer, null: false
      foreign_key :inspection_billing_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :exporter_party_role_id, :party_roles, type: :integer, null: false
      String :booking_reference

      TrueClass :results_captured, default: false
      DateTime :results_captured_at

      TrueClass :api_results_received, default: false

      TrueClass :completed, default: false
      DateTime :completed_at

      TrueClass :inspected, default: false
      String :inspection_point
      TrueClass :awaiting_inspection_results, default: false

      foreign_key :destination_country_id, :destination_countries, type: :integer, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:govt_inspection_sheets,
                   :created_at,
                   function_name: :govt_inspection_sheet_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:govt_inspection_sheets,
                   :updated_at,
                   function_name: :govt_inspection_sheet_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:govt_inspection_sheets, :set_created_at)
    drop_function(:govt_inspection_sheet_set_created_at)
    drop_trigger(:govt_inspection_sheets, :set_updated_at)
    drop_function(:govt_inspection_sheet_set_updated_at)
    drop_table :govt_inspection_sheets
  end
end
