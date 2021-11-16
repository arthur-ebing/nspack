require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:bin_asset_transactions_queue) do
      add_column :created_at, DateTime
    end
    pgt_created_at(:bin_asset_transactions_queue,
                   :created_at,
                   function_name: :bin_asset_transactions_queue_set_created_at,
                   trigger_name: :set_created_at)

    run "UPDATE bin_asset_transactions_queue SET created_at = current_timestamp;"

    alter_table(:bin_asset_transactions_queue) do
      set_column_not_null :created_at
    end
  end

  down do
    drop_trigger(:bin_asset_transactions_queue, :set_created_at)
    drop_function(:bin_asset_transactions_queue_set_created_at)

    alter_table(:bin_asset_transactions_queue) do
      drop_column :created_at
    end
  end
end
