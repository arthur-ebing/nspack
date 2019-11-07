Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Current Delivery', functional_area: 'Raw Materials', program: 'Deliveries', url: '/raw_materials/deliveries/rmt_deliveries/current', seq: 7
  end

  down do
    drop_program_function 'Current Delivery', functional_area: 'Raw Materials', program: 'Deliveries'
  end
end
