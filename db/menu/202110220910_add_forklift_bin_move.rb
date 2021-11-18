Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Forklift Bin Move', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/forklift_bin_move', seq: 4
  end

  down do
    drop_program_function 'Forklift Bin Move', functional_area: 'RMD', program: 'Raw Material'
  end
end
