Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/restore_repacked_pallet/reworks_runs/new', group: 'Restore Repacked Pallet', seq: 40
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/restore_repacked_pallet', group: 'Restore Repacked Pallet', seq: 41
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Restore Repacked Pallet'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Restore Repacked Pallet'
  end
end
