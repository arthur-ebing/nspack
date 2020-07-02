Sequel.migration do
  up do
    alter_table(:inspection_failure_types) do
      add_unique_constraint :failure_type_code, name: :failure_type_code_uniq
    end
  end

  down do
    alter_table(:inspection_failure_types) do
      drop_constraint :failure_type_code_uniq
    end
  end
end
