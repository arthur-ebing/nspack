Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_run_cultivar/reworks_runs/new', group: 'Change Run Cultivar', seq: 44
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_run_cultivar', group: 'Change Run Cultivar', seq: 45
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Change Run Cultivar'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Change Run Cultivar'
  end
end
