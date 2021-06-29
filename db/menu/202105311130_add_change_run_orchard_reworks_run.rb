Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_run_orchard/reworks_runs/new', group: 'Change Run Orchard', seq: 38
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_run_orchard', group: 'Change Run Orchard', seq: 39
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Change Run Orchard'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Change Run Orchard'
  end
end
