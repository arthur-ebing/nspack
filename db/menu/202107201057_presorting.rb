Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Presorting', functional_area: 'Raw Materials', seq: 5
    add_program_function 'Staging Runs', functional_area: 'Raw Materials', program: 'Presorting', url: '/list/presort_staging_runs', seq: 2
    add_program_function 'Search Staging Runs', functional_area: 'Raw Materials', program: 'Presorting', url: '/search/presort_staging_runs', seq: 3
  end

  down do
    drop_program 'Presorting', functional_area: 'Raw Materials'
  end
end