Sequel.migration do
  up do
    alter_table(:reworks_runs) do
      add_column :errors, :jsonb
    end
  end

  down do
    alter_table(:reworks_runs) do
      drop_column :errors
    end
  end
end