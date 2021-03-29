Sequel.migration do
  up do
    alter_table(:marketing_orders) do
      set_column_type :carton_qty_required, Integer
      set_column_type :carton_qty_produced, Integer
    end

    alter_table(:work_orders) do
      set_column_type :carton_qty_required, Integer
      set_column_type :carton_qty_produced, Integer
    end

    alter_table(:work_order_items) do
      set_column_type :carton_qty_required, Integer
      set_column_type :carton_qty_produced, Integer
    end
  end

  down do
    alter_table(:marketing_orders) do
      set_column_type :carton_qty_required, Decimal
      set_column_type :carton_qty_produced, Decimal
    end

    alter_table(:work_orders) do
      set_column_type :carton_qty_required, Decimal
      set_column_type :carton_qty_produced, Decimal
    end

    alter_table(:work_order_items) do
      set_column_type :carton_qty_required, Decimal
      set_column_type :carton_qty_produced, Decimal
    end
  end
end
