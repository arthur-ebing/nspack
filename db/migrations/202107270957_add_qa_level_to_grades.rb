Sequel.migration do
  up do
    alter_table(:grades) do
      add_column :qa_level, Integer
    end
  end

  down do
    alter_table(:grades) do
      drop_column :qa_level
    end
  end
end
