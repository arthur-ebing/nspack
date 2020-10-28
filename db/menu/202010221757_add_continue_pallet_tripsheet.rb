Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Continue Pallet Tripsheet', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/continue_pallet_tripsheet', seq: 8
  end

  down do
    drop_program_function 'Continue Pallet Tripsheet', functional_area: 'RMD', program: 'Finished Goods'
  end
end

