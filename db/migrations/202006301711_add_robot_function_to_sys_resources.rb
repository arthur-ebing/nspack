Sequel.migration do
  up do
    alter_table :system_resources do
      add_column :robot_function, String
    end
  end

  down do
    alter_table :system_resources do
      drop_column :robot_function
    end
  end
end
