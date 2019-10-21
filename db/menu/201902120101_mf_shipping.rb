Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Shipping', functional_area: 'Masterfiles'
    add_program_function 'Voyage Types', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/voyage_types', seq: 1
    add_program_function 'Port Types', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/port_types', seq: 2
    add_program_function 'Ports', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/ports', seq: 3
    add_program_function 'Vessel Types', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/vessel_types', seq: 4
    add_program_function 'Vessels', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/vessels', seq: 5
    add_program_function 'Vehicle Types', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/vehicle_types', seq: 6
    add_program_function 'Depots', functional_area: 'Masterfiles', program: 'Shipping', url: '/list/depots', seq: 7
  end

  down do
    drop_program 'Shipping', functional_area: 'Masterfiles'
  end
end
