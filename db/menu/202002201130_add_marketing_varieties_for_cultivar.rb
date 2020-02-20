Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Marketing Varieties For Cultivars', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/marketing_varieties_for_cultivars', seq: 6, group: 'Cultivars'
  end

  down do
    drop_program_function 'Marketing Varieties For Cultivars', functional_area: 'Masterfiles', program: 'Fruit'
  end
end

