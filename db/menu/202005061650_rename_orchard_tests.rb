Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Orchard Test Types', functional_area: 'Quality', program: 'Config', rename: 'Test Types', seq: 1

    change_program_function 'New Orchard Test Result', functional_area: 'Quality', program: 'Test Results', rename: 'New Test', seq: 1
    change_program_function 'List Orchard Test Results', functional_area: 'Quality', program: 'Test Results', rename: 'List Tests', seq: 2
    change_program_function 'Search Orchard Test Results', functional_area: 'Quality', program: 'Test Results', rename: 'Search Tests', seq: 3
  end

  down do
    change_program_function 'Test Types', functional_area: 'Quality', program: 'Config', rename: 'Orchard Test Types', seq: 1


    change_program_function 'New Test', functional_area: 'Quality', program: 'Test Results', rename: 'New Orchard Test Result', seq: 1
    change_program_function 'List Tests', functional_area: 'Quality', program: 'Test Results', rename: 'List Orchard Test Results', seq: 2
    change_program_function 'Search Tests', functional_area: 'Quality', program: 'Test Results', rename: 'Search Orchard Test Results', seq: 3
  end
end