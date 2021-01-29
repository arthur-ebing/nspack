Sequel.migration do
  up do
    alter_table(:voyage_types) do
      add_column :industry_description, String
    end
  end

  down do
    alter_table(:voyage_types) do
      drop_column :industry_description
    end
  end
end
