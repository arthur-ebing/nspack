
Sequel.migration do
  up do
    alter_table(:destination_countries) do
      add_column :description, String
      add_unique_constraint :country_name, name: :country_unique_name
    end
    alter_table(:destination_regions) do
      add_column :description, String
      add_unique_constraint :destination_region_name, name: :region_unique_name
    end

  end

  down do
    alter_table(:destination_regions) do
      drop_constraint :destination_region_name, name: :region_unique_name
      drop_column :description
    end

    alter_table(:destination_countries) do
      drop_constraint :country_name, name: :country_unique_name
      drop_column :description
    end
  end

end
