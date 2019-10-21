Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Finished Goods'
    add_program 'Dispatch', functional_area: 'Finished Goods', seq: 1
    add_program_function 'Voyages', functional_area: 'Finished Goods', program: 'Dispatch', url: '/list/voyages', seq: 1
    add_program_function 'Loads', functional_area: 'Finished Goods', program: 'Dispatch', url: '/list/loads', seq: 2
  end

  down do
    drop_functional_area 'Finished Goods'
  end
end
