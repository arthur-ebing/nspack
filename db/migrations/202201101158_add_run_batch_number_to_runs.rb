Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_column :run_batch_number, String
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :run_batch_number
    end
  end
end
