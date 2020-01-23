Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'New', match_group: 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/single_pallet_edit/reworks_runs/new'
    change_program_function 'New', match_group: 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/batch_pallet_edit/reworks_runs/new'
    change_program_function 'New', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/scrap_pallet/reworks_runs/new'
    change_program_function 'New', match_group: 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/unscrap_pallet/reworks_runs/new'
    change_program_function 'New', match_group: 'Buildup', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/buildup/reworks_runs/new'
    change_program_function 'New', match_group: 'Tip Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/tip_bins/reworks_runs/new'
    change_program_function 'New', match_group: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/weigh_rmt_bins/reworks_runs/new'
    change_program_function 'New', match_group: 'Recalc Nett Weight', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/recalc_nett_weight/reworks_runs/new'

    change_program_function 'List', match_group: 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/single_pallet_edit'
    change_program_function 'List', match_group: 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/batch_pallet_edit'
    change_program_function 'List', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/scrap_pallet'
    change_program_function 'List', match_group: 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/unscrap_pallet'
    change_program_function 'List', match_group: 'Buildup', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/buildup'
    change_program_function 'List', match_group: 'Tip Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/tip_bins'
    change_program_function 'List', match_group: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/weigh_rmt_bins'
    change_program_function 'List', match_group: 'Recalc Nett Weight', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/recalc_nett_weight'
  end

  down do
    change_program_function 'New', match_group: 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/single_pallet_edit/new'
    change_program_function 'New', match_group: 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/batch_pallet_edit/new'
    change_program_function 'New', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/scrap_pallet/new'
    change_program_function 'New', match_group: 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/unscrap_pallet/new'
    change_program_function 'New', match_group: 'Buildup', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/buildup/new'
    change_program_function 'New', match_group: 'Tip Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/tip_bins/new'
    change_program_function 'New', match_group: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/weigh_rmt_bins/new'
    change_program_function 'New', match_group: 'Recalc Nett Weight', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/recalc_nett_weight/new'

    change_program_function 'List', match_group: 'Single Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/single_pallet_edit'
    change_program_function 'List', match_group: 'Batch Pallet Edit', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/batch_pallet_edit'
    change_program_function 'List', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/scrap_pallet'
    change_program_function 'List', match_group: 'Unscrap Pallet', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/unscrap_pallet'
    change_program_function 'List', match_group: 'Buildup', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/buildup'
    change_program_function 'List', match_group: 'Tip Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/tip_bins'
    change_program_function 'List', match_group: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/weigh_rmt_bins'
    change_program_function 'List', match_group: 'Recalc Nett Weight', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/recalc_nett_weight'
  end
end



