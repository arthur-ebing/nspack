Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_foreign_key :created_by, :users, type: :integer
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :created_by
    end
  end
end