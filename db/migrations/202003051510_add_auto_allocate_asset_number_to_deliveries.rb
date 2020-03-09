Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :auto_allocate_asset_number, TrueClass, default: false
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :auto_allocate_asset_number
    end
  end
end
