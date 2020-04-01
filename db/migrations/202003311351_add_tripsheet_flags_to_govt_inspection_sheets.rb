Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :tripsheet_created, :boolean, default: false
      add_column :tripsheet_created_at, DateTime
      add_column :tripsheet_loaded, :boolean, default: false
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :tripsheet_created
      drop_column :tripsheet_created_at
      drop_column :tripsheet_loaded
    end
  end
end