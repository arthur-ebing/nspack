Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Std Product Weights', functional_area: 'Masterfiles', program: 'Packaging', url: '/list/standard_product_weights', seq: 5, group: 'Pack codes'
  end

  down do
    drop_program_function 'Std Product Weights', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Pack codes'
  end
end