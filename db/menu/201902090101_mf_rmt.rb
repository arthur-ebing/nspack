Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Raw Materials', functional_area: 'Masterfiles'
    add_program_function 'Rmt Delivery Destinations', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/rmt_delivery_destinations'
  end

  down do
    drop_program 'Raw Materials', functional_area: 'Masterfiles'
  end
end
