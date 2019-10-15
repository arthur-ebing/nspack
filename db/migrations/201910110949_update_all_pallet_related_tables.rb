Sequel.migration do
  up do
    alter_table(:pallets) do
      rename_column :exit_ref_date_time, :scrapped_at
      rename_column :shipped_date_time, :shipped_at
      rename_column :govt_first_inspection_date_time, :govt_first_inspection_at
      rename_column :govt_reinspection_date_time, :govt_reinspection_at
      rename_column :internal_inspection_date_time, :internal_inspection_at
      rename_column :internal_reinspection_date_time, :internal_reinspection_at
      rename_column :stock_date_time, :stock_created_at
      rename_column :intake_date_time, :intake_created_at
      rename_column :cold_date_time, :first_cold_storage_at
      rename_column :palletized_date_time, :palletized_at
      rename_column :partially_palletized_date_time, :partially_palletized_at
      add_column :allocated, :boolean, default: false
      add_column :allocated_at, DateTime
      add_column :reinspected, :boolean, default: false
      add_column :scrapped, :boolean, default: false
      add_foreign_key :pallet_format_id, :pallet_formats, key: [:id]
      add_column :carton_quantity, :integer
      add_column :govt_inspection_passed, :boolean, default: false
      add_column :internal_inspection_passed, :boolean, default: false
      add_foreign_key :plt_packhouse_resource_id, :plant_resources, key: [:id], null: false
      add_foreign_key :plt_line_resource_id, :plant_resources, key: [:id], null: false
    end

    alter_table(:pallet_sequences) do
      rename_column :exit_ref_date_time, :scrapped_at
      add_column :verified, :boolean, default: false
      add_column :verification_passed, :boolean, default: false
      set_column_not_null :production_line_resource_id
    end
  end

  down do
    alter_table(:pallets) do
      rename_column :scrapped_at, :exit_ref_date_time
      rename_column :shipped_at, :shipped_date_time
      rename_column :govt_first_inspection_at, :govt_first_inspection_date_time
      rename_column :govt_reinspection_at, :govt_reinspection_date_time
      rename_column :internal_inspection_at, :internal_inspection_date_time
      rename_column :internal_reinspection_at, :internal_reinspection_date_time
      rename_column :stock_created_at, :stock_date_time
      rename_column :intake_created_at, :intake_date_time
      rename_column :first_cold_storage_at, :cold_date_time
      rename_column :palletized_at, :palletized_date_time
      rename_column :partially_palletized_at, :partially_palletized_date_time
      drop_column :allocated
      drop_column :allocated_at
      drop_column :reinspected
      drop_column :scrapped
      drop_column :pallet_format_id
      drop_column :carton_quantity
      drop_column :govt_inspection_passed
      drop_column :internal_inspection_passed
      drop_column :plt_packhouse_resource_id
      drop_column :plt_line_resource_id
    end

    alter_table(:pallet_sequences) do
      rename_column :scrapped_at, :exit_ref_date_time
      drop_column :verified
      drop_column :verification_passed
      set_column_allow_null :production_line_resource_id
    end
  end
end
