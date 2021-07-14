Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'List Bins', functional_area: 'Raw Materials', program: 'Deliveries'
    drop_program_function 'Search Bins', functional_area: 'Raw Materials', program: 'Deliveries'
  end

  down do
    add_program_function 'List Bins', functional_area: 'Raw Materials', program: 'Deliveries', url: '/list/rmt_bins', seq: 4
    add_program_function 'Search Bins', functional_area: 'Raw Materials', program: 'Deliveries', url: '/search/rmt_bins', seq: 5
  end
end
