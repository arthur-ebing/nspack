Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/single_bin_edit/reworks_runs/new', group: 'Single Bin Edit', seq: 50
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/single_bin_edit', group: 'Single Bin Edit', seq: 51
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Single Bin Edit'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Single Bin Edit'
  end
end
