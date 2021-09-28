Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Move Multiple Bins', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/rmt_deliveries/rmt_bins/move_multiple_bins', seq: 4
  end

  down do
    drop_program_function 'Move Multiple Bins', functional_area: 'RMD', program: 'Raw Material'
  end
end
