Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      rename_column :tripsheet_affloaded_at, :tripsheet_offloaded_at
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      rename_column :tripsheet_offloaded_at, :tripsheet_affloaded_at
    end
  end
end
