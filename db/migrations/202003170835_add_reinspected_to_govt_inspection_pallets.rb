Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :reinspection, TrueClass, default: false
    end

    alter_table(:govt_inspection_pallets) do
      add_column :reinspected, TrueClass, default: false
      add_column :reinspected_at, DateTime
    end
  end

  down do
    alter_table(:govt_inspection_pallets) do
      drop_column :reinspected_at
      drop_column :reinspected
    end
    alter_table(:govt_inspection_sheets) do
      drop_column :reinspection
    end
  end
end
