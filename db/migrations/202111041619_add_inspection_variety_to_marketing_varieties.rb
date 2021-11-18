Sequel.migration do
  up do
    alter_table(:marketing_varieties) do
      add_column :inspection_variety, String
    end
  end

  down do
    alter_table(:marketing_varieties) do
      drop_column :inspection_variety
    end
  end
end
