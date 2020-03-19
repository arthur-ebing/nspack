Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      drop_column :created_by
      add_column :created_by, String
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :created_by
      add_column :created_by, Integer
    end
  end
end