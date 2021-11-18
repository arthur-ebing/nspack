Sequel.migration do
  up do
    alter_table(:order_items) do
      set_column_allow_null :actual_count_id
    end
  end

  down do
    alter_table(:order_items) do
      set_column_not_null :actual_count_id
    end
  end
end
