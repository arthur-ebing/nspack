Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_production_run_update/reworks_runs/new', group: 'Bulk Production Run Update', seq: 23
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_production_run_update', group: 'Bulk Production Run Update', seq: 24
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Production Run Update'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Production Run Update'
  end
end
