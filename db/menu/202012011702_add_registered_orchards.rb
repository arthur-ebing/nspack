Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Registered Orchards', functional_area: 'Masterfiles', program: 'Farms', url: '/list/registered_orchards', seq: 5
  end

  down do
    drop_program_function 'Registered Orchards', functional_area: 'Masterfiles', program: 'Farms'
  end
end
