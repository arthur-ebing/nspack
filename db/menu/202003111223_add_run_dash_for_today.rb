Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Dashboard for Today', functional_area: 'Production', program: 'Runs', url: '/list/production_run_dashboard_for_today', seq: 4
  end

  down do
    drop_program_function 'Dashboard for Today', functional_area: 'Production', program: 'Runs'
  end
end
