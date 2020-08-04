require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_delivery_costs, ignore_index_errors: true) do
      foreign_key :rmt_delivery_id, :rmt_deliveries, type: :integer, null: false
      foreign_key :cost_id, :costs, type: :integer, null: false
      Decimal :amount

      index [:rmt_delivery_id, :cost_id], name: :rmt_delivery_id_cost_id_unique_code, unique: true
    end
  end

  down do
    drop_table(:rmt_delivery_costs)
  end
end
