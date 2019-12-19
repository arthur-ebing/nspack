Sequel.migration do
  up do
    alter_table(:pallets) do
      add_column :temp_tail, String
    end
  end

  down do
    alter_table(:pallets) do
      drop_column :temp_tail
    end
  end
end
