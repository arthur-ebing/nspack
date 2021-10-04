Sequel.migration do
  up do
    alter_table(:presort_staging_run_children) do
      add_column :created_from_override, TrueClass, default: false
    end
  end

  down do
    alter_table(:presort_staging_run_children) do
      drop_column :created_from_override
    end
  end
end
