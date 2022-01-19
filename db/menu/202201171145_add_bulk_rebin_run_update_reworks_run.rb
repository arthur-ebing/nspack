Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_rebin_run_update/reworks_runs/new', group: 'Bulk Rebin Run Update', seq: 54
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_rebin_run_update', group: 'Bulk Rebin Run Update', seq: 55
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Rebin Run Update'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Rebin Run Update'
  end
end
