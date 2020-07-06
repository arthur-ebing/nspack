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
    end
  end

  down do
    drop_table(:pallet_buildups)
  end
end
