Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'GTINS', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/gtins', seq: 13
  end

  down do
    drop_program_function 'GTINS', functional_area: 'Masterfiles', program: 'Fruit'
  end
end
