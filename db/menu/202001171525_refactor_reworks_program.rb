Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New - Tip Bins', functional_area: 'Production', program: 'Reworks', group: 'Tip Bins', url: '/production/reworks/reworks_runs/tip_bins/new', seq: 9
    change_program_function 'Tip Bins', rename: 'List - Tip Bins', group: 'Tip Bins', functional_area: 'Production', program: 'Reworks', seq: 10

    add_program_function 'New - Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', group: 'Weigh Rmt Bins', url: '/production/reworks/reworks_runs/weigh_rmt_bins/new', seq: 11
    change_program_function 'Weigh Rmt Bins', rename: 'List - Weigh Rmt Bins', group: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', seq: 12

  end

  down do
    change_program_function 'List - Tip Bins', rename: 'Tip Bins', functional_area: 'Production', program: 'Reworks', group: nil
    drop_program_function 'New - Tip Bins', functional_area: 'Production', program: 'Reworks'

    change_program_function 'List - Weigh Rmt Bins', rename: 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', group: nil
    drop_program_function 'New - Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks'
  end
end
