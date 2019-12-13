Sequel.migration do
  up do
    alter_table(:govt_inspection_pallets) do
      drop_index [:pallet_id], name: :pallet_unique_id
    end
    alter_table(:govt_inspection_sheets) do
      add_column :cancelled, TrueClass, default: false
      add_column :cancelled_at, DateTime
      add_foreign_key :cancelled_id, :govt_inspection_sheets, key: [:id]
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :cancelled
      drop_column :cancelled_at
      drop_foreign_key :cancelled_id
    end
  end
end
