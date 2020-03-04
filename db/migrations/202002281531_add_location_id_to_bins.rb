Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :location_id, Integer
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :location_id
    end
  end
end
