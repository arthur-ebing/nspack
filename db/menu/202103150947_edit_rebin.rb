Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Edit Rebin', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/edit_rebin', seq: 8
  end

  down do
    drop_program_function 'Edit Rebin', functional_area: 'RMD', program: 'Raw Material'
  end
end
