require 'sequel_postgresql_triggers'

Sequel.migration do
  up do
    alter_table(:loads) do
      set_column_allow_null :order_number, true
    end
  end

  down do
    alter_table(:loads) do
      set_column_not_null :order_number
    end
  end
end