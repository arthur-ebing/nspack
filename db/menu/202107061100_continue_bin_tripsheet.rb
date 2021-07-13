Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Continue Bin Tripsheet', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/continue_bins_tripsheet', seq: 11
  end

  down do
    drop_program_function 'Continue Bin Tripsheet', functional_area: 'RMD', program: 'Raw Material'
  end
end