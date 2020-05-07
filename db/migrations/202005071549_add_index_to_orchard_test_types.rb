Sequel.migration do
  up do
    alter_table(:orchard_test_types) do
      add_index :api_attribute, name: :orchard_test_types_api_attribute_idx, unique: true
    end
  end

  down do
    alter_table(:orchard_test_types) do
      drop_index :api_attribute, name: :orchard_test_types_api_attribute_idx
    end
  end
end
