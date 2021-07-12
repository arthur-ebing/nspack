Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Groups', functional_area: 'Masterfiles', program: 'Fruit', match_group: 'Cultivars', rename: 'Cultivar Groups'
  end

  down do
    change_program_function 'Cultivar Groups', functional_area: 'Masterfiles', program: 'Fruit', match_group: 'Cultivars', rename: 'Groups'
  end
end
