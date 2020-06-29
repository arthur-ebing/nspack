Sequel.migration do
  up do
    alter_table(:inventory_codes) do
      add_column :fruit_item_incentive_rate, BigDecimal
    end
  end

  down do
    alter_table(:inventory_codes) do
      drop_column :fruit_item_incentive_rate
    end
  end
end
