Sequel.migration do
  up do
    alter_table(:packing_specification_items) do
      set_column_allow_null :pm_bom_id, true
      set_column_allow_null :pm_mark_id, true
    end
  end

  down do
    alter_table(:packing_specification_items) do
      set_column_allow_null :pm_bom_id, false
      set_column_allow_null :pm_mark_id, false
    end
  end
end
