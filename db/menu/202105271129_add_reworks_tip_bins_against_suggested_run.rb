Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/search_untipped_bins', group: 'Tip Bins Against Suggested Run', seq: 37
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/tip_bins_against_suggested_run', group: 'Tip Bins Against Suggested Run', seq: 38
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Tip Bins Against Suggested Run'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Tip Bins Against Suggested Run'
  end
end
