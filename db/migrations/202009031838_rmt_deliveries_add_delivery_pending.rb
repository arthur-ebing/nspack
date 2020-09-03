Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :delivery_pending, TrueClass, default: false
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :delivery_pending
    end
  end
end
