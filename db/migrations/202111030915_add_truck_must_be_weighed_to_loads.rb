Sequel.migration do
  up do
    alter_table(:loads) do
      add_column :truck_must_be_weighed, TrueClass, default: false
    end
  end

  down do
    alter_table(:loads) do
      drop_column :truck_must_be_weighed
    end
  end
end
