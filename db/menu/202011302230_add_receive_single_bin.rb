Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Receive Bin', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/receive_single_bin', seq: 1
  end

  down do
    drop_program_function 'Receive Bin', functional_area: 'RMD', program: 'Raw Material'
  end
end
