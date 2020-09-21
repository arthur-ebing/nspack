Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Receive Pending Bins', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/raw_materials/receive_bin', seq: 6
  end

  down do
    drop_program_function 'Receive Pending Bins', functional_area: 'RMD', program: 'Raw Material'
  end
end
