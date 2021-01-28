Sequel.migration do
  up do
    alter_table(:product_setups) do
      add_column :rmt_class_id, Integer
    end
  end

  down do
    alter_table(:product_setups) do
      drop_column :rmt_class_id
    end
  end
end
