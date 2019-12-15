Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :tipped_manually, TrueClass, default: false
      add_column :weighed_manually, TrueClass, default: false
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :tipped_manually
      drop_column :weighed_manually
    end
  end
end
