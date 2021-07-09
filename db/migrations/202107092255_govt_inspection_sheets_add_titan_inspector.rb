Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :titan_inspector, String
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :titan_inspector
    end
  end
end