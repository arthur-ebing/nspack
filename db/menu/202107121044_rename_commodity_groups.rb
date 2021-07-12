Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Groups', functional_area: 'Masterfiles', program: 'Fruit', match_group: 'Commodities', rename: 'Commodity Groups'
  end

  down do
    change_program_function 'Commodity Groups', functional_area: 'Masterfiles', program: 'Fruit', match_group: 'Commodities', rename: 'Groups'
  end
end
