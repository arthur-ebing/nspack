Sequel.migration do
  up do
    alter_table :registered_mobile_devices do
      add_foreign_key :act_as_system_resource_id, :system_resources
      add_column :act_as_reader_id, String
    end
  end

  down do
    alter_table :registered_mobile_devices do
      drop_column :act_as_system_resource_id
      drop_column :act_as_reader_id
    end
  end
end
