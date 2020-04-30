require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:orchard_test_api_attributes, ignore_index_errors: true) do
      primary_key :id
      String :api_name, null: false
      String :api_attribute, null: false
      String :description
      column :api_results, 'text[]'

      index [:api_attribute], name: :orchard_test_api_attribute_unique_name, unique: true
    end
  end

  down do
    drop_table(:orchard_test_api_attributes)
  end
end
