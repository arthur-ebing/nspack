Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_column :gross_weight, :decimal
    end

    alter_table(:pallets) do
      add_column :weighed_cartons, :boolean, default: false
    end

    alter_table(:standard_product_weights) do
      add_column :max_gross_weight, :decimal
      add_column :min_gross_weight, :decimal
    end
  end

  down do
    alter_table(:carton_labels) do
      drop_column :gross_weight
    end

    alter_table(:pallets) do
      drop_column :weighed_cartons
    end

    alter_table(:standard_product_weights) do
      drop_column :max_gross_weight
      drop_column :min_gross_weight
    end
  end
end
