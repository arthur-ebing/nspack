Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Create Pallet Tripsheet', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/create_pallet_tripsheet', seq: 7
  end

  down do
    drop_program_function 'Create Pallet Tripsheet', functional_area: 'RMD', program: 'Finished Goods'
  end
end

