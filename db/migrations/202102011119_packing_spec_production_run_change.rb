Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_column :packing_specification_id, :Integer
    end

    alter_table(:product_resource_allocations) do
      add_column :packing_specification_item_id, :Integer
    end

    alter_table(:carton_labels) do
      add_column :rmt_class_id, :Integer
      add_column :packing_specification_item_id, :Integer
      add_column :tu_labour_product_id, :Integer
      add_column :ru_labour_product_id, :Integer
      add_column :fruit_sticker_ids, 'int[]'
      add_column :tu_sticker_ids, 'int[]'
    end

    alter_table(:pallet_sequences) do
      add_column :rmt_class_id, :Integer
      add_column :packing_specification_item_id, :Integer
      add_column :tu_labour_product_id, :Integer
      add_column :ru_labour_product_id, :Integer
      add_column :fruit_sticker_ids, 'int[]'
      add_column :tu_sticker_ids, 'int[]'
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :packing_specification_id
    end

    alter_table(:product_resource_allocations) do
      drop_column :packing_specification_item_id
    end

    alter_table(:carton_labels) do
      drop_column :rmt_class_id
      drop_column :packing_specification_item_id
      drop_column :tu_labour_product_id
      drop_column :ru_labour_product_id
      drop_column :fruit_sticker_ids
      drop_column :tu_sticker_ids
    end

    alter_table(:pallet_sequences) do
      drop_column :rmt_class_id
      drop_column :packing_specification_item_id
      drop_column :tu_labour_product_id
      drop_column :ru_labour_product_id
      drop_column :fruit_sticker_ids
      drop_column :tu_sticker_ids
    end
  end
end
