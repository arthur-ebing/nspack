Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'All', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/recalc_bin_nett_weight/reworks_runs/recalc_all_bins_nett_weight', group: 'Recalc Bin Nett Weight', seq: 36
  end


  down do
    drop_program_function 'All', functional_area: 'Production', program: 'Reworks', match_group: 'Recalc Bin Nett Weight'
  end
end