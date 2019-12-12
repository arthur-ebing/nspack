Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program 'Dispatch', functional_area: 'RMD'
    add_program 'Dispatch', functional_area: 'RMD', seq: 4

    add_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/allocate/load', seq: 1
    add_program_function 'Truck Arrival', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/truck_arrival/load', seq: 2
    add_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/load_truck/load', seq: 3
  end

  down do
    drop_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Dispatch'
  end
end
