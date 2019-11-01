Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Dispatch', functional_area: 'RMD', seq: 4
    add_program_function 'Truck Arrival', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/truck_arrival/load', seq: 1
    add_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/load_truck', seq: 2
  end

  down do
    drop_program 'Dispatch', functional_area: 'RMD'
  end
end
