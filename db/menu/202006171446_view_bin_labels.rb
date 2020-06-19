Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'View Bin Labels', functional_area: 'Raw Materials', program: 'Deliveries', url: '/list/rmt_bin_labels', seq: 9
  end

  down do
    drop_program_function 'View Bin Labels', functional_area: 'Raw Materials', program: 'Deliveries'
  end
end
