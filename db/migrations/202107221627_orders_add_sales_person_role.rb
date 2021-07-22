Sequel.migration do
  up do
    alter_table(:orders) do
      add_foreign_key :sales_person_party_role_id, :party_roles, type: :integer
    end

    alter_table(:order_items) do
      set_column_allow_null :inventory_id
    end
  end

  down do
    alter_table(:orders) do
      drop_foreign_key :sales_person_party_role_id
    end
  end
end
