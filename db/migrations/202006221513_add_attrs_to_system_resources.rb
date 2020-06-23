# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table :system_resources do
      add_column :equipment_type, String
      add_column :module_function, String
      add_column :mac_address, String
      add_column :ip_address, String
      add_column :port, Integer
      add_column :ttl, Integer
      add_column :cycle_time, Integer
      add_column :publishing, :boolean, default: false
      add_column :login, :boolean, default: false
      add_column :logoff, :boolean, default: false
      add_column :module_action, String
      add_column :peripheral_model, String
      add_column :connection_type, String
      add_column :printer_language, String
      add_column :print_username, String
      add_column :print_password, String
      add_column :pixels_mm, Integer
    end
  end

  down do
    alter_table :system_resources do
      drop_column :equipment_type
      drop_column :module_function
      drop_column :mac_address
      drop_column :ip_address
      drop_column :port
      drop_column :ttl
      drop_column :cycle_time
      drop_column :publishing
      drop_column :login
      drop_column :logoff
      drop_column :module_action
      drop_column :peripheral_model
      drop_column :connection_type
      drop_column :printer_language
      drop_column :print_username
      drop_column :print_password
      drop_column :pixels_mm
    end
  end
end
