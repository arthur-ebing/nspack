
Sequel.migration do
  up do
    alter_table(:presort_staging_run_children) do
      drop_index [:farm_id, :presort_staging_run_id], name: :presort_staging_run_child_farm_id_unique
      add_index [:farm_id, :presort_staging_run_id], name: :presort_staging_run_child_farm_id_idx
    end
  end

  down do
    alter_table(:presort_staging_run_children) do
      add_index [:farm_id, :presort_staging_run_id], name: :presort_staging_run_child_farm_id_unique, unique: true
      drop_index [:farm_id, :presort_staging_run_id], name: :presort_staging_run_child_farm_id_idx
    end
  end
end
