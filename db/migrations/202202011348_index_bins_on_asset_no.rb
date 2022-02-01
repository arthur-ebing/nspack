Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      # asset unique?
      add_index [:bin_asset_number], name: :idx_rmt_bins_asset_number, where: 'bin_asset_number IS NOT NULL'
      add_index [:tipped_asset_number], name: :idx_rmt_bins_tipped_asset_number, where: 'tipped_asset_number IS NOT NULL'
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_index [:bin_asset_number], name: :idx_rmt_bins_asset_number
      drop_index [:tipped_asset_number], name: :idx_rmt_bins_tipped_asset_number
    end
  end
end
