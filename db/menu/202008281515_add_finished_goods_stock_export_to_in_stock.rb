Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Export Stock', functional_area: 'Finished Goods', program: 'Stock', url: '/list/stock_pallets/multi?key=export_pack', seq: 2, hide_if_const_false: 'ALLOW_EXPORT_PALLETS_TO_BYPASS_INSPECTION'
  end

  down do
    drop_program_function 'Export Stock', functional_area: 'Finished Goods', program: 'Stock'
  end
end