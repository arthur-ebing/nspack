Sequel.migration do
  up do
    alter_table(:production_run_stats) do
      rename_column :pallets_palletized, :pallets_palletized_full
      rename_column :pallets_inspected, :inspected_pallets
      add_column :pallets_palletized_partial, Integer
    end
  end

  down do
    alter_table(:production_run_stats) do
      rename_column :pallets_palletized_full, :pallets_palletized
      rename_column :inspected_pallets, :pallets_inspected
      drop_column :pallets_palletized_partial
    end
  end
end
