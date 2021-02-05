Sequel.migration do
  up do
    alter_table(:pm_boms_products) do
      set_column_allow_null :quantity
    end
    run "UPDATE pm_boms_products SET quantity = NULL WHERE quantity = 0;"
  end

  down do
    run "UPDATE pm_boms_products SET quantity = 0 WHERE quantity IS NULL;"
    alter_table(:pm_boms_products) do
      set_column_not_null :quantity
    end
  end
end
