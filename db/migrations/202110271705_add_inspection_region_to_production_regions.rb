Sequel.migration do
  up do
    alter_table(:production_regions) do
      add_column :inspection_region, String
    end
  end

  down do
    alter_table(:production_regions) do
      drop_column :inspection_region
    end
  end
end
