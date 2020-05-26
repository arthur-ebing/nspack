Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_weigh_bins/reworks_runs/new', group: 'Bulk Weigh Bins', seq: 30
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_weigh_bins', group: 'Bulk Weigh Bins', seq: 31
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Weigh Bins'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Weigh Bins'
  end
end
