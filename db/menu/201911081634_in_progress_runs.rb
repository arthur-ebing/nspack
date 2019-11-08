Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'In Progress', functional_area: 'Production', seq: 4
    add_program_function 'Active Setups', functional_area: 'Production', program: 'In Progress', url: '/production/in_progress/product_setups/select', restricted: true

    add_program_function 'Dashboard', functional_area: 'Production', program: 'Runs', url: '/list/production_run_dashboard', seq: 3
  end

  down do
    drop_program_function 'Dashboard', functional_area: 'Production', program: 'Runs'

    drop_program 'In Progress', functional_area: 'Production'
  end
end
