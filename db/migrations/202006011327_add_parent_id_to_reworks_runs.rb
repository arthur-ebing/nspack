Sequel.migration do
  up do
    alter_table(:reworks_runs) do
      add_foreign_key :parent_id, :reworks_runs, key: [:id]
    end
  end

  down do
    alter_table(:reworks_runs) do
      drop_column :parent_id
    end
  end
end
