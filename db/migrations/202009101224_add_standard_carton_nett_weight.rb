Sequel.migration do
  up do
    alter_table(:standard_product_weights) do
      add_column :standard_carton_nett_weight, :decimal
      add_column :ratio_to_standard_carton, :decimal
      add_column :is_standard_carton, TrueClass, default: false
    end
  end

  down do
    alter_table(:standard_product_weights) do
      drop_column :standard_carton_nett_weight
      drop_column :ratio_to_standard_carton
      drop_column :is_standard_carton
    end
  end
end