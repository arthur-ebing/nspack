Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    # add_program_function 'New Cargo Temperature', functional_area: 'Masterfiles', program: 'Shipping', url: '/masterfiles/shipping/cargo_temperatures/new', seq: 1
    add_program_function 'Cargo Temperature', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/cargo_temperatures', seq: 8
    # add_program_function 'Search Cargo Temperature', functional_area: 'Masterfiles', program: 'Shipping', url: '/search/cargo_temperatures', seq: 3
  end

  down do
    # drop_program_function 'Search Cargo Temperature', functional_area: 'Masterfiles', program: 'Shipping'
    drop_program_function 'Cargo Temperature', functional_area: 'Masterfiles', program: 'Shipping'
    # drop_program_function 'New Cargo Temperature', functional_area: 'Masterfiles', program: 'Shipping'
  end
end