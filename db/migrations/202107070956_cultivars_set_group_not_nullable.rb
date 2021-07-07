Sequel.migration do
  up do
    alter_table(:cultivars) do
      set_column_not_null :cultivar_group_id
    end
  end

  down do
    alter_table(:cultivars) do
      set_column_allow_null :cultivar_group_id
    end
  end
end
