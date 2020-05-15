Sequel.migration do
  up do
    alter_table(:product_setups) do
      drop_constraint :product_setups_customer_variety_variety_id_fkey
      rename_column :customer_variety_variety_id, :customer_variety_id
    end

    alter_table(:carton_labels) do
      drop_constraint :carton_labels_customer_variety_variety_id_fkey
      rename_column :customer_variety_variety_id, :customer_variety_id
    end

    alter_table(:cartons) do
      drop_constraint :cartons_customer_variety_variety_id_fkey
      rename_column :customer_variety_variety_id, :customer_variety_id
    end

    alter_table(:pallet_sequences) do
      drop_constraint :pallet_sequences_customer_variety_variety_id_fkey
      rename_column :customer_variety_variety_id, :customer_variety_id
    end
  end

  down do
    alter_table(:product_setups) do
      rename_column :customer_variety_id, :customer_variety_variety_id
      add_foreign_key [:customer_variety_variety_id], :customer_variety_varieties, name: :product_setups_customer_variety_variety_id_fkey
    end

    alter_table(:carton_labels) do
      rename_column :customer_variety_id, :customer_variety_variety_id
      add_foreign_key [:customer_variety_variety_id], :customer_variety_varieties, name: :carton_labels_customer_variety_variety_id_fkey
    end

    alter_table(:cartons) do
      rename_column :customer_variety_id, :customer_variety_variety_id
      add_foreign_key [:customer_variety_variety_id], :customer_variety_varieties, name: :cartons_customer_variety_variety_id_fkey
    end

    alter_table(:pallet_sequences) do
      rename_column :customer_variety_id, :customer_variety_variety_id
      add_foreign_key [:customer_variety_variety_id], :customer_variety_varieties, name: :pallet_sequences_customer_variety_variety_id_fkey
    end
  end
end
