Sequel.migration do
  up do
    alter_table(:farms) do
      add_foreign_key :location_id , :locations, key: [:id]
    end
  end

  down do
    alter_table(:farms) do
      drop_column :location_id
    end
  end
end
