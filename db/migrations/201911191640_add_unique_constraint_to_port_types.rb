Sequel.migration do
  up do
    alter_table(:port_types) do
      add_unique_constraint :port_type_code, name: :port_types_port_type_uniq
    end
  end

  down do
    alter_table(:port_types) do
      drop_constraint :port_types_port_type_uniq
    end
  end
end
