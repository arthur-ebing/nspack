require 'sequel_postgresql_triggers'

Sequel.migration do
  up do
    alter_table(:loads) do
      set_column_allow_null :order_number
    end
  end

  down do
    run "UPDATE loads SET order_number = 101 WHERE order_number IS NULL;"
    alter_table(:loads) do
      set_column_not_null :order_number
    end
  end
end