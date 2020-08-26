# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_column :as_edi_location, :boolean, default: false
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :as_edi_location
    end
  end
end
