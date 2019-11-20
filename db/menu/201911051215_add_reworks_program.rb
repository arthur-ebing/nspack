Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Reworks', functional_area: 'Production'
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/list/reworks_run_details', seq: 1
    add_program_function 'Search', functional_area: 'Production', program: 'Reworks', url: '/search/reworks_runs', seq: 2
    add_program_function 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/single_pallet_edit', group: 'Data Change', seq: 3
    add_program_function 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/batch_pallet_edit', group: 'Data Change', seq: 4
    add_program_function 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/scrap_pallet', group: 'Scrap Pallet', seq: 5
    add_program_function 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/unscrap_pallet', group: 'Scrap Pallet', seq: 6
    add_program_function 'Repack Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/repack', seq: 7
    add_program_function 'Buildup', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/buildup', seq: 8
    add_program_function 'Tip Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/tip_bins', seq: 9
  end

  down do
    drop_program 'Reworks', functional_area: 'Production'
  end
end
