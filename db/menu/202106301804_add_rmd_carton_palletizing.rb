Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Robot functions', functional_area: 'RMD', seq: 5
    add_program_function 'Carton palletizing', functional_area: 'RMD', program: 'Robot functions', url: '/rmd/carton_palletizing/login_to_bay'
  end

  down do
    drop_program 'Robot functions', functional_area: 'RMD'
  end
end
