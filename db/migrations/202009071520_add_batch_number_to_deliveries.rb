Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :batch_number, String
      add_column :batch_number_updated_at, DateTime
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :batch_number
      drop_column :batch_number_updated_at
    end
  end
end
