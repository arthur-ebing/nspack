Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :scrapped_bin_asset_number, String
    end

  end

  down do
    alter_table(:rmt_bins) do
      drop_column :scrapped_bin_asset_number
    end
  end
end
