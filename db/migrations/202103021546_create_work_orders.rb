require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:work_orders, ignore_index_errors: true) do
      primary_key :id
      foreign_key :marketing_order_id, :marketing_orders, type: :integer, null: true
      Decimal :carton_qty_required
      Decimal :carton_qty_produced
      Date :start_date
      Date :end_date
      TrueClass :active, default: true
      TrueClass :completed, default: false
      DateTime :completed_at
    end
  end

  down do
    drop_table(:work_orders)
  end
end
