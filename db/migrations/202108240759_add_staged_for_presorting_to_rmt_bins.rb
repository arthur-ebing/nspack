require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_foreign_key :presort_staging_run_child_id, :presort_staging_run_children, null: true, key: [:id]
      add_column :staged_for_presorting, :boolean, default: false
      add_column :staged_for_presorting_at, DateTime
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :presort_staging_run_child_id
      drop_column :staged_for_presorting
      drop_column :staged_for_presorting_at
    end
  end
end