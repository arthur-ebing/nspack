Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_column :lot_no_date, Date
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :lot_no_date
    end
  end
end
