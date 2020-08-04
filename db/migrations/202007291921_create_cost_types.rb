require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:cost_types, ignore_index_errors: true) do
      primary_key :id
      String :cost_type_code, null: false
      String :cost_unit
      String :description
    end
  end

  down do
    drop_table(:cost_types)
  end
end
