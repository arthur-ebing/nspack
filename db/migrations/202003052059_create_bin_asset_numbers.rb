require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:bin_asset_numbers, ignore_index_errors: true) do
      primary_key :id
      String :bin_asset_number
      DateTime :last_used_at
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:bin_asset_number], name: :bin_asset_numbers_unique_bin_asset_number, unique: true
    end

    pgt_created_at(:bin_asset_numbers,
                   :created_at,
                   function_name: :bin_asset_numbers_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:bin_asset_numbers,
                   :updated_at,
                   function_name: :bin_asset_numbers_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('bin_asset_numbers', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:bin_asset_numbers, :audit_trigger_row)
    drop_trigger(:bin_asset_numbers, :audit_trigger_stm)

    drop_trigger(:bin_asset_numbers, :set_created_at)
    drop_function(:bin_asset_numbers_set_created_at)
    drop_trigger(:bin_asset_numbers, :set_updated_at)
    drop_function(:bin_asset_numbers_set_updated_at)
    drop_table(:bin_asset_numbers)
  end
end
