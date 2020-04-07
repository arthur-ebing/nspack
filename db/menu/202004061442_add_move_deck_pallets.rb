Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Move Deck Pallets', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/move_deck_pallets', seq: 4
  end

  down do
    drop_program_function 'Move Deck Pallets', functional_area: 'RMD', program: 'Finished Goods'
  end
end

