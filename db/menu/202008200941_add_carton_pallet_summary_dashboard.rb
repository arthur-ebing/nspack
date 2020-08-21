Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Carton Pallet summary per week', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/carton_pallet_summary_weeks', seq: 8
    add_program_function 'Carton Pallet summary per day', functional_area: 'Production', program: 'Dashboards', url: '/production/dashboards/carton_pallet_summary_days', seq: 9
  end

  down do
    drop_program_function 'Carton Pallet summary per week', functional_area: 'Production', program: 'Dashboards'
    drop_program_function 'Carton Pallet summary per day', functional_area: 'Production', program: 'Dashboards'
  end
end
