Sequel.migration do
  up do
    alter_table(:commodities) do
      add_column :allocate_sample_rmt_bins, :boolean, default: false
    end
  end

  down do
    alter_table(:commodities) do
      drop_column :allocate_sample_rmt_bins
    end
  end
end
