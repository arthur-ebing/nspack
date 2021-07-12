Sequel.migration do
  up do
    alter_table(:commodities) do
      set_column_allow_null :hs_code
    end
  end
  down do
    alter_table(:commodities) do
      set_column_not_null :hs_code
    end
  end
end
