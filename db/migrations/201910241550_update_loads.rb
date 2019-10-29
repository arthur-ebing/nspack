require 'sequel_postgresql_triggers'

Sequel.migration do
  up do
    alter_table(:loads) do
      drop_column :order_number
      add_column :order_number, String
    end
  end

  down do
    alter_table(:loads) do
      drop_column :order_number
      add_column :order_number, String, null: false, default: 123
    end
  end
end