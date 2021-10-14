Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :mixed, TrueClass, default: false
      add_column :presorted, TrueClass, default: false
      add_column :main_presort_run_lot_number, String
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :mixed
      drop_column :presorted
      drop_column :main_presort_run_lot_number
    end
  end
end