# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :current, :boolean, default: false
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :current
    end
  end
end
