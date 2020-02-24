Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :quantity_bins_with_fruit, Integer
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :quantity_bins_with_fruit
    end
  end
end
