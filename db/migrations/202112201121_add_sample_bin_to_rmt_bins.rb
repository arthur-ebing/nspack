Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :sample_bin, :boolean, default: false
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :sample_bin
    end
  end
end
