# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:target_markets) do
      rename_column :is_inspection_tm, :inspection_tm
    end
  end

  down do
    alter_table(:target_markets) do
      rename_column :inspection_tm, :is_inspection_tm
    end
  end
end
