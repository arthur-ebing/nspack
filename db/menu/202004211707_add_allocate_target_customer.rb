Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Allocate Target Customer', functional_area: 'Finished Goods', program: 'Stock', url: '/finished_goods/stock/allocate_target_customer/new', seq: 2
  end

  down do
    drop_program_function 'Allocate Target Customer', functional_area: 'Finished Goods', program: 'Stock'
  end
end

