Sequel.migration do
  up do
    alter_table(:vehicle_jobs) do
      add_column :offload_forced, TrueClass, default: false
    end
  end

  down do
    alter_table(:vehicle_jobs) do
      drop_column :offload_forced
    end
  end
end
