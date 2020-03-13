Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'New', match_group: 'Bulk Production Run Update', functional_area: 'Production', program: 'Reworks', group: 'Bulk Pallet Run Update'
    change_program_function 'List', match_group: 'Bulk Production Run Update', functional_area: 'Production', program: 'Reworks', group: 'Bulk Pallet Run Update'

    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_bin_run_update/reworks_runs/new', group: 'Bulk Bin Run Update', seq: 25
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/bulk_bin_run_update', group: 'Bulk Bin Run Update', seq: 26

    add_program_function 'Search By Pallet Number', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/search_by_pallet_number', seq: 2
  end

  down do
    change_program_function 'New', match_group: 'Bulk Pallet Run Update', functional_area: 'Production', program: 'Reworks', group: 'Bulk Production Run Update'
    change_program_function 'List', match_group: 'Bulk Pallet Run Update', functional_area: 'Production', program: 'Reworks', group: 'Bulk Production Run Update'

    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Bin Run Update'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Bulk Bin Run Update'

    drop_program_function 'Search By Pallet Number', functional_area: 'Production', program: 'Reworks'
  end
end
