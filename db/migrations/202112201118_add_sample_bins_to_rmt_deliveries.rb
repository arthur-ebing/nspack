Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :sample_bins, 'int[]', default: '{}'
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :sample_bins
    end
  end
end
