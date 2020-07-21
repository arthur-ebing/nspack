Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Palletizer Pallets', functional_area: 'Lists', program: 'Pallets', url: '/search/palletizer_pallets', group: 'List', seq: 4

    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/untip_bins/reworks_runs/new', group: 'Untip Bins', seq: 34
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/untip_bins', group: 'Untip Bins', seq: 35
  end

  down do
    drop_program_function 'Palletizer Pallets', functional_area: 'Lists', program: 'Pallets', match_group: 'List'

    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Untip Bins'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Untip Bins'
  end
end
