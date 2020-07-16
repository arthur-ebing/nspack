Sequel.migration do
  up do
    alter_table :rmt_deliveries do
      drop_column :intake_date
    end
  end

  down do
    alter_table :rmt_deliveries do
      add_column :intake_date, DateTime
    end
  end
end
