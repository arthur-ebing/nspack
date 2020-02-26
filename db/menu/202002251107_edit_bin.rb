Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Edit Bin', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/edit_rmt_bin', seq: 2
  end

  down do
    drop_program_function 'Edit Bin', functional_area: 'RMD', program: 'Raw Material'
  end
end
