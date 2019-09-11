require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_deliveries, ignore_index_errors: true) do
      primary_key :id
      foreign_key :orchard_id, :orchards, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer, null: false
      foreign_key :rmt_delivery_destination_id, :rmt_delivery_destinations, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :puc_id, :pucs, type: :integer, null: false
      String :truck_registration_number
      Integer :qty_damaged_bins
      Integer :qty_empty_bins
      TrueClass :active, default: true
      TrueClass :delivery_tipped
      Date :date_picked
      DateTime :date_delivered
      DateTime :tipping_complete_date_time
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      # index [:code], name: :rmt_deliveries_unique_code, unique: true
    end

    pgt_created_at(:rmt_deliveries,
                   :created_at,
                   function_name: :rmt_deliveries_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_deliveries,
                   :updated_at,
                   function_name: :rmt_deliveries_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_deliveries', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:rmt_deliveries, :audit_trigger_row)
    drop_trigger(:rmt_deliveries, :audit_trigger_stm)

    drop_trigger(:rmt_deliveries, :set_created_at)
    drop_function(:rmt_deliveries_set_created_at)
    drop_trigger(:rmt_deliveries, :set_updated_at)
    drop_function(:rmt_deliveries_set_updated_at)
    drop_table(:rmt_deliveries)
  end
end
