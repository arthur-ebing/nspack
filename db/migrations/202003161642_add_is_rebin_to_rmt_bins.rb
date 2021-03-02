Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :is_rebin, :boolean
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :is_rebin
    end
  end
end
