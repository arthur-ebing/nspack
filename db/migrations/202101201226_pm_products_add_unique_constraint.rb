Sequel.migration do
  up do
    alter_table(:pm_products) do
      add_unique_constraint :product_code, name: :product_code_uniq
    end
  end

  down do
    alter_table(:pm_products) do
      drop_constraint :product_code_uniq
    end
  end
end

