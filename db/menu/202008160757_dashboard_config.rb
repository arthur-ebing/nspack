Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Dashboards', functional_area: 'Masterfiles', program: 'Config', url: '/masterfiles/config/dashboards/list', seq: 2, restricted: true
  end

  down do
    drop_program_function 'Dashboards', functional_area: 'Masterfiles', program: 'Config'
  end
end
