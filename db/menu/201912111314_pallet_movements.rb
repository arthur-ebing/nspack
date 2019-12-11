Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Finished Goods', functional_area: 'RMD'
    add_program_function 'Move Pallet', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/pallet_movements/move_pallet', seq: 1
  end

  down do
    drop_program 'Finished Goods', functional_area: 'RMD'
    drop_program_function 'Move Pallet', functional_area: 'RMD', program: 'Finished Goods'
  end
end
