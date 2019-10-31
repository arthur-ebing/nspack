Sequel.migration do
  up do
    alter_table(:production_run_stats) do
      set_column_default :pallets_palletized_partial, 0
    end
  end

  down do
    alter_table(:production_run_stats) do
      set_column_default :pallets_palletized_partial, nil
    end
  end
end
