Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program 'Empty Bins', rename: 'Bin Assets', functional_area: 'Raw Materials'
    change_program_function 'Search Transactions', functional_area: 'Raw Materials', program: 'Bin Assets', url: '/search/bin_asset_transaction_items', seq: 1
    change_program_function 'Transactions', functional_area: 'Raw Materials', program: 'Bin Assets', url: '/list/bin_asset_transaction_items', seq: 2
    change_program_function 'List Locations', functional_area: 'Raw Materials', program: 'Bin Assets', url: '/list/bin_asset_locations', seq: 3

    change_program_function 'Empty Bin Locations', rename: 'Bin Asset Locations', functional_area: 'Masterfiles', program: 'Locations', url: '/list/locations_flat/with_params?key=location_type&location_type=BIN_ASSET', seq: 7
  end

  down do
    change_program 'Bin Assets', rename: 'Empty Bins', functional_area: 'Raw Materials'
    change_program_function 'Search Transactions', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/search/empty_bin_transaction_items', seq: 1
    change_program_function 'Transactions', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/list/empty_bin_transaction_items', seq: 2
    change_program_function 'List Locations', functional_area: 'Raw Materials', program: 'Empty Bins', url: '/list/empty_bin_locations', seq: 3

    change_program_function 'Bin Asset Locations', rename:'Empty Bin Locations', functional_area: 'Masterfiles', program: 'Locations', url: '/list/locations_flat/with_params?key=location_type&location_type=EMPTY_BIN', seq: 7
  end
end
