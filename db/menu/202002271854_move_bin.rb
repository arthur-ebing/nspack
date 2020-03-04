Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Move Bin', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/move_rmt_bin', seq: 3
  end

  down do
    drop_program_function 'Move Bin', functional_area: 'RMD', program: 'Raw Material'
  end
end
