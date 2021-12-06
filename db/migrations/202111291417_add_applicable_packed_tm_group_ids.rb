Sequel.migration do
  up do
    alter_table(:inspection_types) do
      add_column :applies_to_all_packed_tm_groups, TrueClass, default: false
      add_column :applicable_packed_tm_group_ids, 'integer[]'
    end
  end

  down do
    alter_table(:inspection_types) do
      drop_column :applies_to_all_packed_tm_groups
      drop_column :applicable_packed_tm_group_ids
    end
  end
end
