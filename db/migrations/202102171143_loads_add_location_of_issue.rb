Sequel.migration do
  up do
    alter_table(:loads) do
      add_column :location_of_issue, String
    end
  end

  down do
    alter_table(:loads) do
      drop_column :location_of_issue
    end
  end
end
