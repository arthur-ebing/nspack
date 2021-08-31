require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:pallet_buildups) do
      add_column :auto_create_destination_pallet, :boolean, default: false
    end
  end

  down do
    alter_table(:pallet_buildups) do
      drop_column :auto_create_destination_pallet
    end
  end
end