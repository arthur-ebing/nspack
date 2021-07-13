Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Create Bin Tripsheet', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/create_bin_tripsheet', seq: 10
  end

  down do
    drop_program_function 'Create Bin Tripsheet', functional_area: 'RMD', program: 'Raw Material'
  end
end