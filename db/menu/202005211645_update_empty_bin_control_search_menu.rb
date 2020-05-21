Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Search Transactions', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/search/empty_bin_transaction_items', seq: 1
  end

  down do
    change_program_function 'Search Transactions', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/search/empty_bin_transactions', seq: 1
  end
end
