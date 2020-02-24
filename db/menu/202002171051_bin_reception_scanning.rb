Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Raw Material', functional_area: 'RMD'
    add_program_function 'Bin Reception Scanning', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/bin_reception_scanning', seq: 1
  end

  down do
    drop_program_function 'Bin Reception Scanning', functional_area: 'RMD', program: 'Raw Material'
  end
end
