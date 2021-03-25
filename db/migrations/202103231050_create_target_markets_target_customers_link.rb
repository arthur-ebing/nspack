Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:target_markets_target_customers, ignore_index_errors: true) do
      foreign_key :target_market_id, :target_markets, type: :integer, null: false
      foreign_key :target_customer_party_role_id, :party_roles, type: :integer, null: false

      index [:target_market_id, :target_customer_party_role_id], name: :target_markets_target_customers_idx, unique: true
    end
  end

  down do
    drop_table(:target_markets_target_customers)
  end
end
