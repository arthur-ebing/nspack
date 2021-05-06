Sequel.migration do
  up do
    alter_table(:customers) do
      add_column :contact_person_ids, 'integer[]'
    end
  end

  down do
    alter_table(:customers) do
      drop_column :contact_person_ids
    end
  end
end
