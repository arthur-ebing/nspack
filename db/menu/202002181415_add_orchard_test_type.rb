Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Quality'
    add_program 'Config', functional_area: 'Quality', seq: 1
    add_program_function 'Orchard Test Types', functional_area: 'Quality', program: 'Config', url: '/list/orchard_test_types', seq: 1

    add_program 'Test Results', functional_area: 'Quality', seq: 1
    add_program_function 'New Orchard Test Result', functional_area: 'Quality', program: 'Test Results', url: '/quality/test_results/orchard_test_results/new', seq: 1
    add_program_function 'List Orchard Test Results', functional_area: 'Quality', program: 'Test Results', url: '/list/orchard_test_results', seq: 2
    add_program_function 'Search Orchard Test Results', functional_area: 'Quality', program: 'Test Results', url: '/search/orchard_test_results', seq: 3
  end

  down do
    drop_functional_area 'Quality'
  end
end