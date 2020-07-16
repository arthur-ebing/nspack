Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Scrapped', functional_area: 'Lists', program: 'Cartons', url: '/list/scrapped_cartons', seq: 4
    add_program_function 'Cloned', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons/with_params?key=cloned_cartons&is_virtual=true', seq: 5
  end

  down do
    drop_program_function 'Scrapped', functional_area: 'Lists', program: 'Cartons'
    drop_program_function 'Cloned', functional_area: 'Lists', program: 'Cartons'
  end
end
