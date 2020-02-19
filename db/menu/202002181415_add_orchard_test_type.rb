Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Orchard Test Types', functional_area: 'Masterfiles', program: 'Quality', url: '/list/orchard_test_types', seq: 6
  end

  down do
    drop_program_function 'Orchard Test Types', functional_area: 'Masterfiles', program: 'Quality'
  end
end