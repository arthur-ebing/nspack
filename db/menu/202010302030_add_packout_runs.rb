Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Packout Runs', functional_area: 'Production', program: 'Reports', url: '/production/reports/packout_runs', seq: 2
  end

  down do
    drop_program_function 'Packout Runs', functional_area: 'Production', program: 'Reports'
  end
end
