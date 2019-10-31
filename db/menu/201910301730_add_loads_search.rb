Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Voyages', functional_area: 'Finished Goods', program: 'Dispatch', rename: 'List Voyages', seq: 1
    add_program_function 'Search Voyages', functional_area: 'Finished Goods', program: 'Dispatch', url: '/search/voyages', seq: 2
    change_program_function 'Loads', functional_area: 'Finished Goods', program: 'Dispatch', rename: 'List Loads', seq: 3
    add_program_function 'Search Loads', functional_area: 'Finished Goods', program: 'Dispatch', url: '/search/loads', seq: 4

  end

  down do
    change_program_function 'List Voyages', functional_area: 'Finished Goods', program: 'Dispatch', rename: 'Voyages', seq: 1
    drop_program_function 'Search Voyages', functional_area: 'Finished Goods', program: 'Dispatch'
    change_program_function 'List Loads', functional_area: 'Finished Goods', program: 'Dispatch', rename: 'Loads', seq: 2
    drop_program_function 'Search Loads', functional_area: 'Finished Goods', program: 'Dispatch'
  end
end
