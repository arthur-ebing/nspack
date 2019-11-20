Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallets', url: '/list/scrapped_pallets/with_params?key=scrapped&scrapped=true', seq: 8

    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/scrapped_pallet_sequences/with_params?key=scrapped&scrapped=true', seq: 8
  end

  down do
    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=scrapped&scrapped=true', seq: 8

    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=scrapped&scrapped=true', seq: 8
  end
end
