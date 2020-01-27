Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/change_deliveries_orchard', group: 'Change Deliveries Orchards', seq: 1
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_deliveries_orchards', group: 'Change Deliveries Orchards', seq: 2
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks'
  end
end
