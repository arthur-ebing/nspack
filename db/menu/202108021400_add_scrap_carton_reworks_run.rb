Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/scrap_carton/reworks_runs/new', group: 'Scrap Carton', seq: 46
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/scrap_carton', group: 'Scrap Carton', seq: 47

    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/unscrap_carton/reworks_runs/new', group: 'Unscrap Carton', seq: 48
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/unscrap_carton', group: 'Unscrap Carton', seq: 49
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Carton'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Scrap Carton'

    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Unscrap Carton'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Unscrap Carton'
  end
end
