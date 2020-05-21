Sequel.migration do
  up do
    alter_table(:empty_bin_transactions) do
      set_column_allow_null :empty_bin_to_location_id, true
      set_column_allow_null :reference_number, true
    end
  end

  down do
    alter_table(:empty_bin_transactions) do
      set_column_allow_null :empty_bin_to_location_id, false
      set_column_allow_null :reference_number, false
    end
  end
end
