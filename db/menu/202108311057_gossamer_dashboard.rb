Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Gossamer data', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/gossamer_data', seq: 13
  end

  down do
    drop_program_function 'Gossamer data', functional_area: 'Production', program: 'Dashboards'
  end
end
