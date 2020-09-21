Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Batches', functional_area: 'Raw Materials', program: 'Deliveries', url: '/list/delivery_batches', seq: 10
  end

  down do
    drop_program_function 'Batches', functional_area: 'Raw Materials', program: 'Deliveries'
  end
end
