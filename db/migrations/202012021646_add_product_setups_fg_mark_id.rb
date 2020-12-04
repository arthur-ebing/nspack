Sequel.migration do
  up do
    alter_table(:product_setups) do
      add_foreign_key :pm_mark_id , :pm_marks, key: [:id]
    end

    alter_table(:carton_labels) do
      add_foreign_key :pm_mark_id , :pm_marks, key: [:id]
    end

    alter_table(:pallet_sequences) do
      add_foreign_key :pm_mark_id , :pm_marks, key: [:id]
    end

    alter_table(:pm_marks) do
      drop_index [:mark_id], name: :pm_mark_unique_fruitspec_mark
      add_index [:mark_id, :packaging_marks], name: :pm_mark_unique_fruitspec_mark, unique: true
    end

    alter_table(:pm_types) do
      add_column :short_code, String
    end

    alter_table(:pm_subtypes) do
      add_column :short_code, String
    end

    alter_table(:pm_products) do
      add_column :gross_weight_per_unit, :decimal
      add_column :items_per_unit, :integer
      drop_index [:product_code], name: :pm_products_idx
    end

  end

  down do
    alter_table(:product_setups) do
      drop_column :pm_mark_id
    end

    alter_table(:carton_labels) do
      drop_column :pm_mark_id
    end

    alter_table(:pallet_sequences) do
      drop_column :pm_mark_id
    end

    alter_table(:pm_marks) do
      drop_index [:mark_id, :packaging_marks], name: :pm_mark_unique_fruitspec_mark
      add_index [:mark_id], name: :pm_mark_unique_fruitspec_mark, unique: true
    end

    alter_table(:pm_types) do
      drop_column :short_code
    end

    alter_table(:pm_subtypes) do
      drop_column :short_code
    end

    alter_table(:pm_products) do
      drop_column :gross_weight_per_unit
      drop_column :items_per_unit
      add_index [:product_code], name: :pm_products_idx, unique: true
    end
  end
end
