Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program 'Dispatch', functional_area: 'RMD', seq: 4

    change_program_function 'Truck Arrival', functional_area: 'RMD', program: 'Dispatch', seq: 2
    change_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', seq: 3
    add_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/allocate/load', seq: 1
  end

  down do
    drop_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Dispatch'
  end
end
