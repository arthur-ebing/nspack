Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Search Production runs', functional_area: 'Production', program: 'Runs', url: '/production/runs/production_runs/search'
  end

  down do
    change_program_function 'Search Production runs', functional_area: 'Production', program: 'Runs', url: '/search/production_runs'
  end
end



