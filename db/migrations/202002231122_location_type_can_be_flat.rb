# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:location_types) do
      add_column :hierarchical, TrueClass, default: true
    end
  end

  down do
    alter_table(:location_types) do
      drop_column :hierarchical
    end
  end
end
