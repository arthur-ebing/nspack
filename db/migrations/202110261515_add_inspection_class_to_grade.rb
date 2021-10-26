Sequel.migration do
  up do
    alter_table(:grades) do
      add_column :inspection_class, String
    end
  end

  down do
    alter_table(:grades) do
      drop_column :inspection_class
    end
  end
end
