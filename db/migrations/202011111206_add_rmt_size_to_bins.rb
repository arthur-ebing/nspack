Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_foreign_key :rmt_size_id, :rmt_sizes, key: [:id]
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_foreign_key [:rmt_size_id]
    end
  end
end
