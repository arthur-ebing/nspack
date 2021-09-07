Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Empty Pallet Location', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/pallet_movements/empty_pallet_location', seq: 9
  end

  down do
    drop_program_function 'Empty Pallet Location', functional_area: 'RMD', program: 'Finished Goods'
  end
end
