Sequel.migration do
  up do
    alter_table(:commodities) do
      set_column_allow_null :hs_code
    end
  end
  down do
    run "UPDATE commodities SET hs_code = 'TEXT' WHERE hs_code IS NULL;"

    alter_table(:commodities) do
      set_column_not_null :hs_code
    end
  end
end
