Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :keep_open, TrueClass , default: false
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :keep_open
    end
  end
end
