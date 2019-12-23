Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Search Loads by Pallet', functional_area: 'Finished Goods', program: 'Dispatch', url: '/finished_goods/dispatch/loads/search_load_by_pallet', seq: 5

  end

  down do
    drop_program_function 'Search Loads by Pallet', functional_area: 'Finished Goods', program: 'Dispatch'

  end
end