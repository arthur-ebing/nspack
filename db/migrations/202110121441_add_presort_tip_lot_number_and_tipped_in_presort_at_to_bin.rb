Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :presort_tip_lot_number, String
      add_column :tipped_in_presort_at, DateTime
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :presort_tip_lot_number
      drop_column :tipped_in_presort_at
    end
  end
end