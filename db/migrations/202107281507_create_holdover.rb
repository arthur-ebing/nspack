require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pallet_holdovers, ignore_index_errors: true) do
      primary_key :id
      foreign_key :pallet_id, :pallets, type: :integer, null: false
      Integer :holdover_quantity, null: false
      String :buildup_remarks, size: 255

      TrueClass :completed, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[pallet_id]
    end
    pgt_created_at(:pallet_holdovers,
                   :created_at,
                   function_name: :pallet_holdovers_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pallet_holdovers,
                   :updated_at,
                   function_name: :pallet_holdovers_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:pallet_holdovers, :set_created_at)
    drop_function(:pallet_holdovers_set_created_at)
    drop_trigger(:pallet_holdovers, :set_updated_at)
    drop_function(:pallet_holdovers_set_updated_at)
    drop_table(:pallet_holdovers)
  end
end
