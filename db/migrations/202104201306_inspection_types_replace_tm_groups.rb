Sequel.migration do
  up do
    alter_table(:inspection_types) do
      drop_column :applies_to_all_tm_groups
      drop_column :applicable_tm_group_ids

      add_column :applicable_tm_ids, 'integer[]'
      add_column :applies_to_all_tms, TrueClass, default: false

      add_column :applicable_tm_customer_ids, 'integer[]'
      add_column :applies_to_all_tm_customers, TrueClass, default: false
    end
  end

  down do
    alter_table(:inspection_types) do
      drop_column :applies_to_all_tm_customers
      drop_column :applicable_tm_customer_ids

      drop_column :applies_to_all_tms
      drop_column :applicable_tm_ids

      add_column :applicable_tm_group_ids, 'integer[]'
      add_column :applies_to_all_tm_groups, TrueClass, default: false
    end
  end
end
