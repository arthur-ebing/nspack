Sequel.migration do
  up do
    alter_table(:loads) do
      add_column :allocated, TrueClass, default: false
      add_column :allocated_at, DateTime
      rename_column :shipped_date, :shipped_at
    end
  end

  down do
    alter_table(:loads) do
      drop_column :allocated
      drop_column :allocated_at
      rename_column :shipped_at, :shipped_date
    end
  end
end


