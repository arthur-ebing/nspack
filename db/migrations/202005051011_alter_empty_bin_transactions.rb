Sequel.migration do
  up do
    alter_table(:empty_bin_transactions) do
      set_column_allow_null :empty_bin_to_location_id, true
      set_column_allow_null :reference_number, true
    end

    run "UPDATE program_functions
         SET url = '/search/empty_bin_transaction_items'
         WHERE program_functions.program_function_name = 'Search Transactions';"

    run "DELETE FROM asset_transaction_types
         WHERE transaction_type_code = 'ADHOC_EMPTY_BIN_MOVE';"

    run "DELETE FROM asset_transaction_types
         WHERE transaction_type_code = 'BOOKOUT_BINS';"
  end

  down do
    alter_table(:empty_bin_transactions) do
      set_column_allow_null :empty_bin_to_location_id, false
      set_column_allow_null :reference_number, false
    end

    run "UPDATE program_functions
         SET url = '/search/empty_bin_transactions'
         WHERE program_functions.program_function_name = 'Search Transactions';"
  end
end
