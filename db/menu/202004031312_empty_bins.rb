Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Empty Bins', functional_area: 'Raw Materials'
    add_program_function 'Search Transactions', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/search/empty_bin_transactions', seq: 1
    add_program_function 'Transactions', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/list/empty_bin_transaction_items', seq: 2
    add_program_function 'List Locations', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/list/empty_bin_locations', seq: 3

    add_program_function 'List Asset Transaction Types', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/asset_transaction_types', seq: 2
  end

  down do
    drop_program_function 'List Asset Transaction Types', functional_area: 'Masterfiles', program: 'Raw Materials'

    drop_program 'Empty Bins', functional_area: 'Raw Materials'
  end
end