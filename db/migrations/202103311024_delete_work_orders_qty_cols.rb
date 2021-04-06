Sequel.migration do
  up do
    alter_table(:marketing_orders) do
      drop_column :carton_qty_required
      drop_column :carton_qty_produced
    end

    alter_table(:work_orders) do
      drop_column :carton_qty_required
      drop_column :carton_qty_produced
    end
  end

  down do
    alter_table(:marketing_orders) do
      add_column :carton_qty_required, Integer
      add_column :carton_qty_produced, Integer
    end

    alter_table(:work_orders) do
      add_column :carton_qty_required, Integer
      add_column :carton_qty_produced, Integer
    end
  end
end
