Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Pallets in stock (per size)', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/in_stock_per_size', seq: 6
    change_program_function 'Deliveries per week', functional_area: 'Production', program: 'Dashboards', seq: 7
    change_program_function 'Deliveries per day', functional_area: 'Production', program: 'Dashboards', seq: 8
    change_program_function 'Carton Pallet summary per week', functional_area: 'Production', program: 'Dashboards', seq: 9
    change_program_function 'Carton Pallet summary per day', functional_area: 'Production', program: 'Dashboards', seq: 10
  end

  down do
    drop_program_function 'Pallets in stock (per size)', functional_area: 'Production', program: 'Dashboards'
    change_program_function 'Deliveries per week', functional_area: 'Production', program: 'Dashboards', seq: 6
    change_program_function 'Deliveries per day', functional_area: 'Production', program: 'Dashboards', seq: 7
    change_program_function 'Carton Pallet summary per week', functional_area: 'Production', program: 'Dashboards', seq: 8
    change_program_function 'Carton Pallet summary per day', functional_area: 'Production', program: 'Dashboards', seq: 9
  end
end
