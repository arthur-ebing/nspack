Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_column :carton_equals_pallet, TrueClass, default: false
      add_column :pallet_number, String
      add_column :phc, String
    end

    alter_table(:cartons) do
      add_column :pallet_number, String
      add_column :phc, String
    end
  end

  down do
    alter_table(:carton_labels) do
      drop_column :carton_equals_pallet
      drop_column :pallet_number
      drop_column :phc
    end

    alter_table(:cartons) do
      drop_column :pallet_number
      drop_column :phc
    end
  end
end
