Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/scrap_bin/reworks_runs/new', group: 'Scrap Bin', seq: 19
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/scrap_bin', group: 'Scrap Bin', seq: 20
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Bin'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Bin'
  end
end
