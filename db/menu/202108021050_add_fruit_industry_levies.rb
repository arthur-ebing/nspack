Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Fruit Industry Levies', functional_area: 'Masterfiles', program: 'Parties', url: '/list/fruit_industry_levies', seq: 8
  end

  down do
    drop_program_function 'Fruit Industry Levies', functional_area: 'Masterfiles', program: 'Parties'
  end
end

