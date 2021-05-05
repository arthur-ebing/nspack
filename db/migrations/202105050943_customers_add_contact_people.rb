Sequel.migration do
  up do
    run "INSERT INTO roles (name) values ('CUSTOMER_CONTACT_PERSON')"
    alter_table(:customers) do
      add_column :contact_person_ids, 'integer[]'
    end
  end

  down do
    run "DELETE FROM roles WHERE name = 'CUSTOMER_CONTACT_PERSON'"
    alter_table(:customers) do
      drop_column :contact_person_ids
    end
  end
end
