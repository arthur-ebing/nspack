Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'View Deck Pallets', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/view_deck_pallets', seq: 3
  end

  down do
    drop_program_function 'View Deck Pallets', functional_area: 'RMD', program: 'Finished Goods'
  end
end
