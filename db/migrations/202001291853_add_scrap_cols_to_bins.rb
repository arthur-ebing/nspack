Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_column :scrap_reason_id, Integer
      add_column :scrap_remarks, String
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :scrap_reason_id
      drop_column :scrap_remarks
    end
  end
end
