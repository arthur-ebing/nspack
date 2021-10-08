Sequel.migration do
  up do
    alter_table(:bin_integration_queue) do
      add_column :delivery_data, :jsonb
      add_column :is_bin_error, TrueClass, default: false
      add_column :is_delivery_error, TrueClass, default: false
    end
  end

  down do
    alter_table(:bin_integration_queue) do
      drop_column :delivery_data
      drop_column :is_bin_error
      drop_column :is_delivery_error
    end
  end
end