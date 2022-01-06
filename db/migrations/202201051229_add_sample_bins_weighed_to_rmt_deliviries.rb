Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :sample_bins_weighed, TrueClass, default: false
      add_column :sample_weights_extrapolated_at, DateTime
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :sample_bins_weighed
      drop_column :sample_weights_extrapolated_at
    end
  end
end
