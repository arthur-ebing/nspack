Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/unscrap_bin/reworks_runs/new', group: 'Unscrap Bin', seq: 21
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/unscrap_bin', group: 'Unscrap Bin', seq: 22
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Unscrap Bin'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Unscrap Bin'
  end
end
