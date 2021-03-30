Sequel.migration do
  up do
    alter_table(:product_setups) do
      add_foreign_key :target_customer_party_role_id , :party_roles, key: [:id]
    end

  end

  down do
    alter_table(:product_setups) do
      drop_foreign_key :target_customer_party_role_id
    end
  end
end
