Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/tip_mixed_orchards/reworks_runs/new', group: 'Tip Mixed Orchards', seq: 37
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/tip_mixed_orchards', group: 'Tip Mixed Orchards', seq: 38
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Tip Mixed Orchards'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Tip Mixed Orchards'
  end
end
