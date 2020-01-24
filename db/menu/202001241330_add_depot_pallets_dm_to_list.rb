Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Shipped', group: 'Depot Pallets', functional_area: 'Lists', program: 'Pallets', url: '/list/fg_pallets/with_params?key=shipped_depot_pallet', seq: 12
    add_program_function 'Stock', group: 'Depot Pallets', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=in_stock_depot_pallet', seq: 13
  end

  down do
    drop_program_function 'Shipped', match_group: 'Depot Pallets', functional_area: 'Lists', program: 'Pallets'
    drop_program_function 'Stock', match_group: 'Depot Pallets', functional_area: 'Lists', program: 'Pallets'
  end
end
