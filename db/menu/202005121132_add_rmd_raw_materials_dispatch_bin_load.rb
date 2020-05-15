Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Bin Load', functional_area: 'RMD', program: 'Raw Material', group: 'Dispatch', url: '/rmd/raw_materials/dispatch/bin_load', seq: 1
  end

  down do
    drop_program_function 'Bin Load', functional_area: 'RMD', program: 'Raw Material', match_group: 'Dispatch'
  end
end