Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/weigh_rmt_bins', seq: 10
  end

  down do
    drop_program_function 'Weigh Rmt Bins', functional_area: 'Production', program: 'Reworks'
  end
end
