Sequel.migration do
  up do
    alter_table(:vehicle_jobs) do
      add_foreign_key :rmt_delivery_id , :rmt_deliveries, key: [:id], null: true
    end
  end

  down do
    alter_table(:vehicle_jobs) do
      drop_column :rmt_delivery_id
    end
  end
end
