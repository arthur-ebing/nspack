require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_foreign_key :order_item_id, :order_items, type: :integer
    end

    run "UPDATE pallet_sequences
         SET order_item_id = (SELECT order_item_id
                              FROM order_items_pallet_sequences
                              WHERE pallet_sequences.id = order_items_pallet_sequences.pallet_sequence_id)"

    drop_trigger(:order_items_pallet_sequences, :audit_trigger_row)
    drop_trigger(:order_items_pallet_sequences, :audit_trigger_stm)

    drop_trigger(:order_items_pallet_sequences, :set_created_at)
    drop_function(:order_items_pallet_sequences_set_created_at)
    drop_trigger(:order_items_pallet_sequences, :set_updated_at)
    drop_function(:order_items_pallet_sequences_set_updated_at)
    drop_table :order_items_pallet_sequences
  end

  down do
    extension :pg_triggers
    create_table(:order_items_pallet_sequences, ignore_index_errors: true) do
      primary_key :id
      foreign_key :order_item_id, :order_items, null: false
      foreign_key :pallet_sequence_id, :pallet_sequences, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[order_item_id pallet_sequence_id]
    end

    pgt_created_at(:order_items_pallet_sequences,
                   :created_at,
                   function_name: :order_items_pallet_sequences_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:order_items_pallet_sequences,
                   :updated_at,
                   function_name: :order_items_pallet_sequences_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('order_items_pallet_sequences', true, true, '{updated_at}'::text[]);"

    run "INSERT INTO order_items_pallet_sequences (pallet_sequence_id, order_item_id)
         SELECT id, order_item_id
         FROM pallet_sequences
         WHERE order_item_id IS NOT NULL"

    alter_table(:pallet_sequences) do
      drop_column :order_item_id
    end
  end
end




