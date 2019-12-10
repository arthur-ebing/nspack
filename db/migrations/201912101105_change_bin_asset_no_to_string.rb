Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      set_column_type :bin_asset_number, String
      set_column_type :tipped_asset_number, String
    end

    run <<~SQL
      UPDATE rmt_bins
      SET bin_asset_number = 'SK' || bin_asset_number
      WHERE bin_asset_number IS NOT NULL;

      UPDATE rmt_bins
      SET tipped_asset_number = 'SK' || tipped_asset_number
      WHERE tipped_asset_number IS NOT NULL;
    SQL
  end

  down do
    # NB: the conversion back from string to int needs to be done in SQL with the USING clause:
    run <<~SQL
      UPDATE rmt_bins
      SET bin_asset_number = replace(bin_asset_number, 'SK', '')
      WHERE bin_asset_number IS NOT NULL;

      UPDATE rmt_bins
      SET tipped_asset_number = replace(tipped_asset_number, 'SK', '')
      WHERE tipped_asset_number IS NOT NULL;

      ALTER TABLE rmt_bins ALTER COLUMN bin_asset_number TYPE integer USING (trim(bin_asset_number)::integer);
      ALTER TABLE rmt_bins ALTER COLUMN tipped_asset_number TYPE integer USING (trim(tipped_asset_number)::integer);
    SQL
  end
end
