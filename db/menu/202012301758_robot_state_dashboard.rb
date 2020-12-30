Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Robot states', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/robot_states', seq: 12
  end

  down do
    drop_program_function 'Robot states', functional_area: 'Production', program: 'Dashboards'
  end
end
