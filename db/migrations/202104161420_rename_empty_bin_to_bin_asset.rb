require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    # empty_bin_locations to bin_asset_locations
    rename_table(:empty_bin_locations, :bin_asset_locations)

    # empty_bin_transaction_items to bin_asset_transaction_items
    drop_trigger(:empty_bin_transaction_items, :set_created_at)
    drop_function(:empty_bin_transaction_items_set_created_at)
    drop_trigger(:empty_bin_transaction_items, :set_updated_at)
    drop_function(:empty_bin_transaction_items_set_updated_at)

    rename_table(:empty_bin_transaction_items, :bin_asset_transaction_items)

    pgt_created_at(:bin_asset_transaction_items,
                   :created_at,
                   function_name: :bin_asset_transaction_items_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_asset_transaction_items,
                   :updated_at,
                   function_name: :bin_asset_transaction_items_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('bin_asset_transaction_items', true, true, '{updated_at}'::text[]);"

    # empty_bin_transactions to bin_asset_transactions
    drop_trigger(:empty_bin_transactions, :set_created_at)
    drop_function(:empty_bin_transactions_set_created_at)
    drop_trigger(:empty_bin_transactions, :set_updated_at)
    drop_function(:empty_bin_transactions_set_updated_at)

    rename_table(:empty_bin_transactions, :bin_asset_transactions)

    pgt_created_at(:bin_asset_transactions,
                   :created_at,
                   function_name: :bin_asset_transactions_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_asset_transactions,
                   :updated_at,
                   function_name: :bin_asset_transactions_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('bin_asset_transactions', true, true, '{updated_at}'::text[]);"

    alter_table(:bin_asset_transaction_items) do
      rename_column :empty_bin_transaction_id, :bin_asset_transaction_id
      rename_column :empty_bin_from_location_id, :bin_asset_from_location_id
      rename_column :empty_bin_to_location_id, :bin_asset_to_location_id
    end

    alter_table(:bin_asset_transactions) do
      rename_column :empty_bin_to_location_id, :bin_asset_to_location_id
    end

    run "UPDATE location_types SET location_type_code = 'BIN_ASSET', short_code = 'BIN_ASSET' WHERE location_type_code = 'EMPTY_BIN';"
  end

  down do
    # empty_bin_locations to bin_asset_locations
    rename_table(:bin_asset_locations, :empty_bin_locations)

    # empty_bin_transaction_items to bin_asset_transaction_items
    drop_trigger(:bin_asset_transaction_items, :set_created_at)
    drop_function(:bin_asset_transaction_items_set_created_at)
    drop_trigger(:bin_asset_transaction_items, :set_updated_at)
    drop_function(:bin_asset_transaction_items_set_updated_at)

    rename_table(:bin_asset_transaction_items, :empty_bin_transaction_items)

    pgt_created_at(:empty_bin_transaction_items,
                   :created_at,
                   function_name: :empty_bin_transaction_items_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:empty_bin_transaction_items,
                   :updated_at,
                   function_name: :empty_bin_transaction_items_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('empty_bin_transaction_items', true, true, '{updated_at}'::text[]);"

    # empty_bin_transactions to bin_asset_transactions
    drop_trigger(:bin_asset_transactions, :set_created_at)
    drop_function(:bin_asset_transactions_set_created_at)
    drop_trigger(:bin_asset_transactions, :set_updated_at)
    drop_function(:bin_asset_transactions_set_updated_at)

    rename_table(:bin_asset_transactions, :empty_bin_transactions)

    pgt_created_at(:empty_bin_transactions,
                   :created_at,
                   function_name: :empty_bin_transactions_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:empty_bin_transactions,
                   :updated_at,
                   function_name: :empty_bin_transactions_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('empty_bin_transactions', true, true, '{updated_at}'::text[]);"

    alter_table(:empty_bin_transaction_items) do
      rename_column :bin_asset_transaction_id, :empty_bin_transaction_id
      rename_column :bin_asset_from_location_id, :empty_bin_from_location_id
      rename_column :bin_asset_to_location_id, :empty_bin_to_location_id
    end

    alter_table(:empty_bin_transactions) do
      rename_column :bin_asset_to_location_id, :empty_bin_to_location_id
    end

    run "UPDATE location_types SET location_type_code = 'EMPTY_BIN', short_code = 'EMPTY_BIN' WHERE location_type_code = 'BIN_ASSET';"
  end
end
