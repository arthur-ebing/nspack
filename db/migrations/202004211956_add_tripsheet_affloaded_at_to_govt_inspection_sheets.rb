Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :tripsheet_affloaded_at, DateTime
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :tripsheet_affloaded_at
    end
  end
end