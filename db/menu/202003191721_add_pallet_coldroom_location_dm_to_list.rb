Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Coldroom Locations', functional_area: 'Lists', program: 'Pallets', url: '/list/pallet_coldroom_locations', seq: 14
  end

  down do
    drop_program_function 'Coldroom Locations', functional_area: 'Lists', program: 'Pallets'
  end
end
