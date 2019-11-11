Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/load_truck/load'
  end

  down do
    change_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/load_truck'
  end
end