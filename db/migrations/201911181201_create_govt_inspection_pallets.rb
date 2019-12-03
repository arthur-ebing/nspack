require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:govt_inspection_pallets, ignore_index_errors: true) do
      primary_key :id
      foreign_key :pallet_id, :pallets, type: :integer, null: false
      foreign_key :govt_inspection_sheet_id, :govt_inspection_sheets, type: :integer, null: false

      TrueClass :passed, default: false

      TrueClass :inspected, default: false
      DateTime :inspected_at

      foreign_key :failure_reason_id, :inspection_failure_reasons, type: :integer
      String :failure_remarks

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:pallet_id], name: :pallet_unique_id, unique: true
    end

    pgt_created_at(:govt_inspection_pallets,
                   :created_at,
                   function_name: :govt_inspection_pallet_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:govt_inspection_pallets,
                   :updated_at,
                   function_name: :govt_inspection_pallet_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:govt_inspection_pallets, :set_created_at)
    drop_function(:govt_inspection_pallet_set_created_at)
    drop_trigger(:govt_inspection_pallets, :set_updated_at)
    drop_function(:govt_inspection_pallet_set_updated_at)
    drop_table :govt_inspection_pallets
  end
end
