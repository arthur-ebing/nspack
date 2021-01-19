require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:pm_products) do
      add_foreign_key :std_fruit_size_count_id, :std_fruit_size_counts
    end
  end

  down do
    alter_table(:pm_products) do
      drop_column :std_fruit_size_count_id
    end
  end
end
