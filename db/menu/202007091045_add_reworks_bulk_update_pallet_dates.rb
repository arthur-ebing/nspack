Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_update_pallet_dates/reworks_runs/new', group: 'Bulk Update Pallet Dates', seq: 32
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_update_pallet_dates', group: 'Bulk Update Pallet Dates', seq: 33
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Update Pallet Dates'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Update Pallet Dates'
  end
end
