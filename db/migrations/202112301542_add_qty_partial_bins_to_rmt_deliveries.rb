Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :qty_partial_bins, Integer, default: 0, null: false
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :qty_partial_bins
    end
  end
end
