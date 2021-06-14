Sequel.migration do
  up do
    alter_table(:orders) do
      add_column :pricing_per_kg, TrueClass, default: false
    end
  end

  down do
    alter_table(:orders) do
      drop_column :pricing_per_kg
    end
  end
end
