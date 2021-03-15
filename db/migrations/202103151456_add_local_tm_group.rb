Sequel.migration do
  up do
    alter_table(:target_market_groups) do
      add_column :local_tm_group, TrueClass, default: false
    end
  end

  down do
    alter_table(:target_market_groups) do
      drop_column :local_tm_group
    end
  end
end
