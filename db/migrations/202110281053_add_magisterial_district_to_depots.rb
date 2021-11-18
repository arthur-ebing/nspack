Sequel.migration do
  up do
    alter_table(:depots) do
      add_column :magisterial_district, String
    end
  end

  down do
    alter_table(:depots) do
      drop_column :magisterial_district
    end
  end
end
