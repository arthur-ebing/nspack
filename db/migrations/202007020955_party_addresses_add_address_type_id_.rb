Sequel.migration do
  up do
    alter_table :party_addresses do
      add_foreign_key :address_type_id, :address_types
      add_unique_constraint [:party_id, :address_type_id], name: :party_address_type_unique_code
    end

    run <<~SQL
      UPDATE party_addresses
      SET address_type_id = subquery.address_type_id
      FROM (SELECT id, address_type_id
            FROM addresses) AS subquery
      WHERE party_addresses.address_id = subquery.id;
    SQL

    alter_table(:party_addresses) do
      set_column_not_null :address_type_id
    end
  end

  down do
    alter_table :party_addresses do
      drop_constraint :party_address_type_unique_code
      drop_column :address_type_id
    end
  end
end
