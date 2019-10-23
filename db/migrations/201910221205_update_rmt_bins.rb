Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :scrapped, TrueClass, default: false
      add_column :scrapped_at, DateTime
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :scrapped
      drop_column :scrapped_at
    end
  end
end
