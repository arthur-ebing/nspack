Sequel.migration do
  up do
    alter_table(:reworks_runs) do
      add_column :bins_scrapped, 'integer[]'
      add_column :bins_unscrapped, 'integer[]'
    end
  end

  down do
    alter_table(:reworks_runs) do
      drop_column :bins_scrapped
      drop_column :bins_unscrapped
    end
  end
end
