Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Move Multiple Pallets', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/pallet_movements/move_multiple_pallets', seq: 2
  end

  down do
    drop_program_function 'Move Multiple Pallets', functional_area: 'RMD', program: 'Finished Goods'
  end
end
