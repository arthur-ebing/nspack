Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :tripsheet_created, :boolean, default: false
      add_column :tripsheet_created_at, DateTime
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :tripsheet_created
      drop_column :tripsheet_created_at
    end
  end
end
