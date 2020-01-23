Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Single Pallet Edit', url: '/production/reworks/reworks_runs/single_pallet_edit/new', seq: 3
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Batch Pallet Edit', url: '/production/reworks/reworks_runs/batch_pallet_edit/new', seq: 5
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Scrap Pallet', url: '/production/reworks/reworks_runs/scrap_pallet/new', seq: 7
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Unscrap Pallet', url: '/production/reworks/reworks_runs/unscrap_pallet/new', seq: 9
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Buildup', url: '/production/reworks/reworks_runs/buildup/new', seq: 11
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Tip Bins', url: '/production/reworks/reworks_runs/tip_bins/new', seq: 13
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', group: 'Weigh Rmt Bins', url: '/production/reworks/reworks_runs/weigh_rmt_bins/new', seq: 15

    change_program_function 'Single Pallet Edit', rename: 'List', group: 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', match_group: 'Data Change', seq: 4
    change_program_function 'Batch Pallet Edit', rename: 'List', group: 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', match_group: 'Data Change',seq: 6
    change_program_function 'Scrap Pallet', rename: 'List', group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Pallet', seq: 8
    change_program_function 'Unscrap Pallet', rename: 'List', group: 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Pallet', seq: 10
    change_program_function 'Buildup', rename: 'List', group: 'Buildup', functional_area: 'Production', program: 'Reworks', seq: 12
    change_program_function 'Tip Bins', rename: 'List', group: 'Tip Bins', functional_area: 'Production', program: 'Reworks', seq: 14
    change_program_function 'Weigh Rmt Bins', rename: 'List', group: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', seq: 16

    drop_program_function 'Repack Pallet', functional_area: 'Production', program: 'Reworks'
  end

  down do
    add_program_function 'Repack Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/repack', seq: 7

    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Single Pallet Edit'
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Batch Pallet Edit'
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Pallet'
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Unscrap Pallet'
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Buildup'
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Tip Bins'
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Weigh Rmt Bins'

    change_program_function 'List', match_group: 'Single Pallet Edit', rename: 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', group: 'Data Change', seq: 3
    change_program_function 'List', match_group: 'Batch Pallet Edit', rename: 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', group: 'Data Change', seq: 4
    change_program_function 'List', match_group: 'Scrap Pallet', rename: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', group: 'Scrap Pallet', seq: 5
    change_program_function 'List', match_group: 'Unscrap Pallet', rename: 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', group: 'Scrap Pallet', seq: 6
    change_program_function 'List', match_group: 'Buildup', rename: 'Buildup', functional_area: 'Production', program: 'Reworks', seq: 8, group: nil
    change_program_function 'List', match_group: 'Tip Bins', rename: 'Tip Bins', functional_area: 'Production', program: 'Reworks', seq: 9, group: nil
    change_program_function 'List', match_group: 'Weigh Rmt Bins', rename: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', seq: 10, group: nil
  end
end



