Sequel.migration do
  up do
    alter_table(:reworks_runs) do
      add_column :bg_work_completed, TrueClass, default: false
    end
  end

  down do
    alter_table(:reworks_runs) do
      drop_column :bg_work_completed
    end
  end
end