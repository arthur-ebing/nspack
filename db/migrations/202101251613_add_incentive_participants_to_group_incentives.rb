Sequel.migration do
  up do
    alter_table(:group_incentives) do
      add_column :incentive_target_worker_ids, 'int[]', default: '{}'
      add_column :incentive_non_target_worker_ids, 'int[]', default: '{}'
    end
  end

  down do
    alter_table(:group_incentives) do
      drop_column :incentive_target_worker_ids
      drop_column :incentive_non_target_worker_ids
    end
  end
end
