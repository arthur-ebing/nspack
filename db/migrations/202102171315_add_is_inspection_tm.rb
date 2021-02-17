Sequel.migration do
  up do
    alter_table(:target_markets) do
      add_column :is_inspection_tm, TrueClass, default: false
    end
  end

  down do
    alter_table(:target_markets) do
      drop_column :is_inspection_tm
    end
  end
end
