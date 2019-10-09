
require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      add_column :material_mass, Numeric
      add_column :plant_resource_button_indicator, String
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      drop_column :material_mass
      drop_column :plant_resource_button_indicator
    end
  end
end
