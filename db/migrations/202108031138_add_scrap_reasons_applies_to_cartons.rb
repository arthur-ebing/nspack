Sequel.migration do
  up do
    alter_table(:scrap_reasons) do
      add_column :applies_to_cartons, TrueClass, default: false
    end

    alter_table(:reworks_runs) do
      add_column :cartons_scrapped, 'integer[]'
      add_column :cartons_unscrapped, 'integer[]'
    end
  end

  down do
    alter_table(:scrap_reasons) do
      drop_column :applies_to_cartons
    end

    alter_table(:reworks_runs) do
      drop_column :cartons_scrapped
      drop_column :cartons_unscrapped
    end
  end
end
