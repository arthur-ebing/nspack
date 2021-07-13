Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :tripsheet_loaded, :boolean, default: false
      add_column :tripsheet_loaded_at, DateTime
      add_column :tripsheet_offloaded, :boolean, default: false
      add_column :tripsheet_offloaded_at, DateTime
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :tripsheet_loaded
      drop_column :tripsheet_loaded_at
      drop_column :tripsheet_offloaded
      drop_column :tripsheet_offloaded_at
    end
  end
end
