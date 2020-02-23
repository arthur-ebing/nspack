Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Empty Bin Locations', functional_area: 'Masterfiles', program: 'Locations', url: '/list/locations_flat/with_params?key=location_type&location_type=EMPTY_BIN', seq: 7
  end

  down do
    drop_program_function 'Empty Bin Locations', functional_area: 'Masterfiles', program: 'Locations'
  end
end
