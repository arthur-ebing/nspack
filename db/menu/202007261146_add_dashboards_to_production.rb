Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Production runs', functional_area: 'Production', program: 'Runs', url: '/production/dashboards/production_runs', group: 'Dashboards', seq: 8
    add_program_function 'Palletizing bay states', functional_area: 'Production', program: 'Runs', url: '/production/dashboards/palletizing_bays', group: 'Dashboards', seq: 9, hide_if_const_false: 'USE_CARTON_PALLETIZING'
  end

  down do
    drop_program_function 'Production runs', functional_area: 'Production', program: 'Runs', match_group: 'Dashboards'
    drop_program_function 'Palletizing bay states', functional_area: 'Production', program: 'Runs', match_group: 'Dashboards'
  end
end
