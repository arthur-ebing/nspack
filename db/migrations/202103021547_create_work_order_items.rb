require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:work_order_items, ignore_index_errors: true) do
      primary_key :id
      foreign_key :work_order_id, :work_orders, type: :integer, null: false
      foreign_key :product_setup_id, :product_setups, type: :integer, null: false
      Decimal :carton_qty_required
      Decimal :carton_qty_produced
      TrueClass :completed, default: false
      DateTime :completed_at

      index [:work_order_id, :product_setup_id], name: :work_order_items_unique_code, unique: true
    end
  end

  down do
    drop_table(:work_order_items)
  end
end
