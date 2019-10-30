Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'List Voyages', functional_area: 'Finished Goods', program: 'Dispatch', url: '/list/voyages', seq: 1
    add_program_function 'Search Voyages', functional_area: 'Finished Goods', program: 'Dispatch', url: '/search/voyages', seq: 2
    add_program_function 'List Loads', functional_area: 'Finished Goods', program: 'Dispatch', url: '/list/loads', seq: 3
    add_program_function 'Search Loads', functional_area: 'Finished Goods', program: 'Dispatch', url: '/search/loads', seq: 4
    drop_program_function 'Loads', functional_area: 'Finished Goods', program: 'Dispatch'
    drop_program_function 'Voyages', functional_area: 'Finished Goods', program: 'Dispatch'
  end

  down do
    add_program_function 'Voyages', functional_area: 'Finished Goods', program: 'Dispatch', url: '/list/voyages', seq: 1
    add_program_function 'Loads', functional_area: 'Finished Goods', program: 'Dispatch', url: '/list/loads', seq: 2
    drop_program_function 'List Loads', functional_area: 'Finished Goods', program: 'Dispatch'
    drop_program_function 'Search Loads', functional_area: 'Finished Goods', program: 'Dispatch'
    drop_program_function 'List Voyages', functional_area: 'Finished Goods', program: 'Dispatch'
    drop_program_function 'Search Voyages', functional_area: 'Finished Goods', program: 'Dispatch'
  end
end
