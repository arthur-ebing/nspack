Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'WIP Pallets', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/wip_pallets/reworks_runs/work_in_progress', seq: 52
    add_program_function 'WIP Bins', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/wip_bins/reworks_runs/work_in_progress', seq: 53
  end

  down do
    drop_program_function 'WIP Pallets', functional_area: 'Production', program: 'Reworks'
    drop_program_function 'WIP Bins', functional_area: 'Production', program: 'Reworks'
  end
end
