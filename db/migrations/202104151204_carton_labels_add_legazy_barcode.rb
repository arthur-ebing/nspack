Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_column :legacy_carton_number, String
    end
  end

  down do
    alter_table(:carton_labels) do
      drop_column :legacy_carton_number
    end
  end
end
