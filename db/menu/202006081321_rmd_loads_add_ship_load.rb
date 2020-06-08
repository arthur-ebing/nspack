Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Ship Load', functional_area: 'RMD', program: 'Finished Goods', group: 'Dispatch', url: '/rmd/finished_goods/dispatch/ship_load', seq: 5
  end

  down do
    drop_program_function 'Ship Load', functional_area: 'RMD', program: 'Finished Goods', match_group: 'Dispatch'
  end
end