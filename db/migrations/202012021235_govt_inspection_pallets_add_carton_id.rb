Sequel.migration do
  up do
    alter_table(:govt_inspection_pallets) do
      add_foreign_key :carton_id, :cartons, type: :integer
      add_index [:govt_inspection_sheet_id, :pallet_id], name: :pallet_inspection_unique_id, unique: true
    end
  end

  down do
    alter_table(:govt_inspection_pallets) do
      drop_index [:govt_inspection_sheet_id, :pallet_id], name: :pallet_inspection_unique_id
      drop_column :carton_id
    end
  end
end
