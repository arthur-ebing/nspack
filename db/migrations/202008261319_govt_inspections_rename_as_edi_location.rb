# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      rename_column :as_edi_location, :use_inspection_destination_for_load_out
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      rename_column :use_inspection_destination_for_load_out, :as_edi_location
    end
  end
end
