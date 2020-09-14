Sequel.migration do
  up do
    alter_table(:rmt_deliveries) do
      rename_column :delivery_pending, :received
    end

    run <<~SQL
      UPDATE rmt_deliveries SET received = TRUE;
    SQL
  end

  down do
    alter_table(:rmt_deliveries) do
      rename_column :received, :delivery_pending
    end
  end
end
