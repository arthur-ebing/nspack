Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=daily_pack&in_stock=false&shipped=false', seq: 3

    change_program_function 'List', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallet_sequences', seq: 1
    change_program_function 'Search', functional_area: 'Lists', program: 'Pallet Sequences', url: '/search/pallet_sequences', seq: 2
    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=daily_pack&in_stock=false&shipped=false', seq: 3
  end

  down do
    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=daily_pack&in_stock=false', seq: 3

    change_program_function 'List', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallets', seq: 1
    change_program_function 'Search', functional_area: 'Lists', program: 'Pallet Sequences', url: '/search/pallets', seq: 2
    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=daily_pack&in_stock=false', seq: 3
  end
end

