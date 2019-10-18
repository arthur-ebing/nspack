
require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:pallet_bases) do
      add_column :material_mass, Numeric
    end
  end

  down do
    alter_table(:pallet_bases) do
      drop_column :material_mass
    end
  end
end