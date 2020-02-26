Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :unscrapped_at, DateTime
    end

  end

  down do
    alter_table(:rmt_bins) do
      drop_column :unscrapped_at
    end
  end
end
