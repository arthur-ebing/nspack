Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      add_column :shipped, :boolean, default: false
    end
  end

  down do
    alter_table(:rmt_deliveries) do
      drop_column :shipped
    end
  end
end
