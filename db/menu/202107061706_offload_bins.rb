Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Offload Bins', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/offload_bins', seq: 12
  end

  down do
    drop_program_function 'Offload Bins', functional_area: 'RMD', program: 'Raw Material'
  end
end