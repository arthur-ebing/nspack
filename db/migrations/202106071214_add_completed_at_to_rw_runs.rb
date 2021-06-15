Sequel.migration do
  up do
    alter_table(:reworks_runs) do
      add_column :completed_at, DateTime
    end
  end

  down do
    alter_table(:reworks_runs) do
      drop_column :completed_at
    end
  end
end