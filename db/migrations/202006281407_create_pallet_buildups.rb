require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pallet_buildups, ignore_index_errors: true) do
      primary_key :id
      String :destination_pallet_number, null: false
      column :source_pallets, 'text[]', null: false
      Integer :qty_cartons_to_move
      String :created_by
      DateTime :completed_at
      Jsonb :cartons_moved
      TrueClass :completed, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:pallet_buildups,
                   :created_at,
                   function_name: :pallet_buildups_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pallet_buildups,
                   :updated_at,
                   function_name: :pallet_buildups_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('pallet_buildups', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:pallet_buildups, :audit_trigger_row)
    drop_trigger(:pallet_buildups, :audit_trigger_stm)

    drop_trigger(:pallet_buildups, :set_created_at)
    drop_function(:pallet_buildups_set_created_at)
    drop_trigger(:pallet_buildups, :set_updated_at)
    drop_function(:pallet_buildups_set_updated_at)
    drop_table(:pallet_buildups)
  end
end
