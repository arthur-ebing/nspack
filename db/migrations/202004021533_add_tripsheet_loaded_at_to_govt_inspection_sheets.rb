Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :tripsheet_loaded_at, DateTime
      add_column :tripsheet_offloaded, :boolean, default: false
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :tripsheet_loaded_at
      drop_column :tripsheet_offloaded
    end
  end
end