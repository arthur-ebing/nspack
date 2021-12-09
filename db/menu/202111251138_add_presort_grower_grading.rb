Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Presort Grower Grading', functional_area: 'Raw Materials'
    add_program_function 'Presort Grading Pools', functional_area: 'Raw Materials', program: 'Presort Grower Grading', url: '/list/presort_grower_grading_pools', seq: 1
    add_program_function 'Search Presort Grading Pools', functional_area: 'Raw Materials', program: 'Presort Grower Grading', url: '/search/presort_grower_grading_pools', seq: 2
    add_program_function 'Search Presort Grading Bins', functional_area: 'Raw Materials', program: 'Presort Grower Grading', url: '/search/presort_grower_grading_bins', seq: 3
  end

  down do
    drop_program 'Presort Grower Grading', functional_area: 'Raw Materials'
  end
end


