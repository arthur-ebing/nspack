Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Raw Materials'
    add_program 'Deliveries', functional_area: 'Raw Materials'
    add_program_function 'New Delivery', functional_area: 'Raw Materials', program: 'Deliveries', url: '/raw_materials/deliveries/rmt_deliveries/new'
    add_program_function 'Deliveries', functional_area: 'Raw Materials', program: 'Deliveries', url: '/list/rmt_deliveries', seq: 2
    add_program_function 'Search Deliveries', functional_area: 'Raw Materials', program: 'Deliveries', url: '/search/rmt_deliveries', seq: 3
    add_program_function 'List Bins', functional_area: 'Raw Materials', program: 'Deliveries', url: '/list/rmt_bins', seq: 4
    add_program_function 'Search Bins', functional_area: 'Raw Materials', program: 'Deliveries', url: '/search/rmt_bins', seq: 5
  end

  down do
    drop_functional_area 'Raw Materials'
  end
end
