Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Create Rebin', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/create_rebin', seq: 4
  end

  down do
    drop_program_function 'Create Rebin', functional_area: 'RMD', program: 'Raw Material'
  end
end
