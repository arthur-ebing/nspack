Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_bin_delivery/reworks_runs/new', group: 'Change Bin Delivery', seq: 42
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_bin_delivery', group: 'Change Bin Delivery', seq: 43
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Change Bin Delivery'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Change Bin Delivery'
  end
end
