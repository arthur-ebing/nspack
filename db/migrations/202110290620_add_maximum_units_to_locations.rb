Sequel.migration do
  up do
    alter_table(:locations) do
      add_column :maximum_units, Integer, default: 0
    end
  end

  down do
    alter_table(:locations) do
      drop_column :maximum_units
    end
  end
end
