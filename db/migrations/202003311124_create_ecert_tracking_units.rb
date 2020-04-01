require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # -- ecert_tracking_units
    create_table(:ecert_tracking_units, ignore_index_errors: true) do
      primary_key :id
      foreign_key :pallet_id, :pallets, null: false
      foreign_key :ecert_agreement_id, :ecert_agreements, null: false
      Integer :business_id, null: false
      String :industry, null: false
      String :elot_key
      String :verification_key
      TrueClass :passed, null: false, default: false
      column :process_result, 'text[]'
      column :rejection_reasons, 'text[]'

      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

    end

    pgt_created_at(:ecert_tracking_units,
                   :created_at,
                   function_name: :ecert_tracking_units_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:ecert_tracking_units,
                   :updated_at,
                   function_name: :ecert_tracking_units_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    # Drop logging for ecert_tracking_units table.
    drop_trigger(:ecert_tracking_units, :set_created_at)
    drop_function(:ecert_tracking_units_set_created_at)
    drop_trigger(:ecert_tracking_units, :set_updated_at)
    drop_function(:ecert_tracking_units_set_updated_at)
    drop_table(:ecert_tracking_units)
  end
end
