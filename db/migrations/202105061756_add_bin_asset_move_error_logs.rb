Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:bin_asset_transactions_queue, ignore_index_errors: true) do
      primary_key :id
      Integer :rmt_bin_id, null: false
      String :bin_event_type, null: false
      TrueClass :pallet, default: false
      String :changes_made, text: true
    end

    alter_table(:bin_asset_transactions) do
      add_column :changes_made, :jsonb
      add_column :affected_rmt_bin_ids, 'integer[]'
    end

    create_table(:bin_asset_move_error_logs, ignore_index_errors: true) do
      primary_key :id
      foreign_key :bin_asset_location_id, :bin_asset_locations, type: :integer, null: false
      Integer :quantity, default: 0
      TrueClass :completed, default: false
      String :error_message
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:bin_asset_move_error_logs,
                   :created_at,
                   function_name: :bin_asset_move_error_logs_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_asset_move_error_logs,
                   :updated_at,
                   function_name: :bin_asset_move_error_logs_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_table(:bin_asset_transactions_queue)
    drop_table(:bin_asset_move_error_logs)

    alter_table(:bin_asset_transactions) do
      drop_column :changes_made
      drop_column :affected_rmt_bin_ids
    end
  end
end
