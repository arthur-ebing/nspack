require 'sequel_postgresql_triggers'

Sequel.migration do
  up do
    alter_table(:load_containers) do
      set_column_allow_null :container_seal_code
      set_column_allow_null :internal_container_code
    end
  end

  down do
    run "UPDATE load_containers SET container_seal_code = 101 WHERE container_seal_code IS NULL;
         UPDATE load_containers SET internal_container_code = 101 WHERE internal_container_code IS NULL;"
    alter_table(:load_containers) do
      set_column_not_null :container_seal_code
      set_column_not_null :internal_container_code
    end
  end
end