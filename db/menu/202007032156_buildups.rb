Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Buildups', functional_area: 'Finished Goods', seq: 4
    add_program_function 'Recent', functional_area: 'Finished Goods', program: 'Buildups', url: '/list/pallet_buildups', seq: 1
    add_program_function 'Completed', functional_area: 'Finished Goods', program: 'Buildups', url: '/finished_goods/buildups/completed', seq: 2
    add_program_function 'Uncompleted', functional_area: 'Finished Goods', program: 'Buildups', url: '/finished_goods/buildups/uncompleted', seq: 3
  end

  down do
    drop_program 'Buildups', functional_area: 'Finished Goods'
    drop_program_function 'Recent', functional_area: 'Finished Goods', program: 'Buildups'
    drop_program_function 'Completed', functional_area: 'Finished Goods', program: 'Buildups'
    drop_program_function 'Uncompleted', functional_area: 'Finished Goods', program: 'Buildups'
  end
end
