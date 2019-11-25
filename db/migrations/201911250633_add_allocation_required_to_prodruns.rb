Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_column :allocation_required, TrueClass, default: true
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :allocation_required
    end
  end
end
