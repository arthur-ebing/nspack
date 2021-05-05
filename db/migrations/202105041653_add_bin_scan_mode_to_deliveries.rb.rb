Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :bin_scan_mode, Integer
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :bin_scan_mode
    end
  end
end
