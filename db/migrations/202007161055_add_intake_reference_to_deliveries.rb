Sequel.migration do
  up do
    alter_table :rmt_deliveries do
      add_column :reference_number, String
      add_column :intake_date, DateTime
    end
  end

  down do
    alter_table :rmt_deliveries do
      drop_column :reference_number
      drop_column :intake_date
    end
  end
end
