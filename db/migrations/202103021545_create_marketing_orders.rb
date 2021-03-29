require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:marketing_orders, ignore_index_errors: true) do
      primary_key :id
      foreign_key :customer_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
      String :order_number, null: false
      String :order_reference
      Decimal :carton_qty_required
      Decimal :carton_qty_produced
      TrueClass :completed, default: false
      DateTime :completed_at
    end
  end

  down do
    drop_table(:marketing_orders)
  end
end
