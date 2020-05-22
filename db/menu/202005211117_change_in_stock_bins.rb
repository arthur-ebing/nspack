Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'In Stock', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins/with_params?key=in_stock', seq: 4
    add_program_function 'Shipped', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins/with_params?key=shipped', seq: 5
  end

  down do
    drop_program_function 'Shipped', functional_area: 'Lists', program: 'Bins'
    change_program_function 'In Stock', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins/with_params?key=tipped&tipped=false', seq: 4
  end
end
