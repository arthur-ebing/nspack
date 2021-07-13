Sequel.migration do
  up do
    alter_table(:vehicle_jobs) do
      add_column :items_moved_from_job_id, :Integer
    end
  end

  down do
    alter_table(:vehicle_jobs) do
      drop_column :items_moved_from_job_id
    end
  end
end
