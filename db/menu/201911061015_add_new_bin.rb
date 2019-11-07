Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New Bin', functional_area: 'Raw Materials', program: 'Deliveries', url: '/raw_materials/deliveries/rmt_bins/new', seq: 6
  end

  down do
    drop_program_function 'New Bin', functional_area: 'Raw Materials', program: 'Deliveries'
  end
end
