Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Add Finding Sheet Pallets', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets', seq: 6
  end

  down do
    drop_program_function 'Add Finding Sheet Pallets', functional_area: 'RMD', program: 'Finished Goods'
  end
end
