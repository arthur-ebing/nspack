Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :cooled, TrueClass, default: true
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :cooled
    end
  end
end
