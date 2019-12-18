Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Stock', functional_area: 'Finished Goods', seq: 1
    add_program_function 'Local Stock', functional_area: 'Finished Goods', program: 'Stock', url: '/list/stock_pallets/with_params?key=local_pack', seq: 1
  end

  down do
    drop_program 'Stock', functional_area: 'Finished Goods'
  end
end