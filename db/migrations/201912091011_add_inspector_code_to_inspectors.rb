Sequel.migration do
  up do
    alter_table(:inspectors) do
      add_column :inspector_code, String
      add_unique_constraint :inspector_code, name: :inspector_code_uniq
    end


  end

  down do
    alter_table(:inspectors) do
      drop_constraint :inspector_code_uniq
      drop_column :inspector_code
    end
  end
end

