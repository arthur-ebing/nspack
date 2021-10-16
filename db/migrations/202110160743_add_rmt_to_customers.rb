Sequel.migration do
  up do
    alter_table(:customers) do
      add_column :rmt_customer, TrueClass, default: false
    end

    run "UPDATE roles SET specialised = true WHERE name = 'RMT_CUSTOMER';"

    run <<~SQL
      INSERT INTO customers (customer_party_role_id, rmt_customer, default_currency_id, currency_ids)
      SELECT id, true, (SELECT id FROM currencies LIMIT 1), ARRAY(SELECT id FROM currencies LIMIT 1)
      FROM party_roles
      WHERE role_id = (SELECT id FROM roles WHERE name = 'RMT_CUSTOMER')
      ON CONFLICT DO NOTHING;
    SQL
  end

  down do
    run 'DELETE FROM customers WHERE rmt_customer;'

    run "UPDATE roles SET specialised = false WHERE name = 'RMT_CUSTOMER';"

    alter_table(:customers) do
      drop_column :rmt_customer
    end
  end
end
