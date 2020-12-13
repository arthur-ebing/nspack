Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Bin state', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/bin_state', seq: 11
  end

  down do
    drop_program_function 'Bin state', functional_area: 'Production', program: 'Dashboards'
  end
end

