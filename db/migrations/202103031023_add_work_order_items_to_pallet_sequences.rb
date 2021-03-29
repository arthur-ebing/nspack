Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_foreign_key :work_order_item_id , :work_order_items, key: [:id], null: true
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_column :work_order_item_id
    end
  end
end
