Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Dashboards', functional_area: 'Production', seq: 8
    move_program_function 'Production runs', functional_area: 'Production', program: 'Runs', to_program: 'Dashboards'
    move_program_function 'Palletizing bay states', functional_area: 'Production', program: 'Runs', to_program: 'Dashboards'
    # change: seq, group
    change_program_function 'Production runs', functional_area: 'Production', program: 'Dashboards', match_group: 'Dashboards', group: nil, seq: 1
    change_program_function 'Palletizing bay states', functional_area: 'Production', program: 'Dashboards', match_group: 'Dashboards', group: nil, seq: 2

    add_program_function 'Loads per week', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/load_weeks', seq: 3
    add_program_function 'Loads per day', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/load_days', seq: 4
    add_program_function 'Pallets in stock', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/in_stock', seq: 5
    add_program_function 'Deliveries per week', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/delivery_weeks', seq: 6
    add_program_function 'Deliveries per day', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/delivery_days', seq: 7
  end

  down do
    move_program_function 'Production runs', functional_area: 'Production', program: 'Dashboards', to_program: 'Runs'
    move_program_function 'Palletizing bay states', functional_area: 'Production', program: 'Dashboards', to_program: 'Runs'
    # change: seq, group
    change_program_function 'Production runs', functional_area: 'Production', program: 'Runs', group: 'Dashboards', seq: 8
    change_program_function 'Palletizing bay states', functional_area: 'Production', program: 'Runs', group: 'Dashboards', seq: 9

    drop_program 'Dashboards', functional_area: 'Production'
  end
end
