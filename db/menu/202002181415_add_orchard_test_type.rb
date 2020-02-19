Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Quality'
    add_program 'Config', functional_area: 'Quality', seq: 1
    add_program_function 'Orchard Test Types', functional_area: 'Quality', program: 'Config', url: '/list/orchard_test_types', seq: 1
  end

  down do
    drop_functional_area 'Quality'
  end
end