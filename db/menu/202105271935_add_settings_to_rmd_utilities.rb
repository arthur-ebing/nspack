Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Device settings', functional_area: 'RMD', program: 'Utilities', url: '/rmd/utilities/settings', seq: 3
    add_program_function 'Setup Device', functional_area: 'RMD', program: 'Utilities', url: '/rmd/utilities/settings/maintain', seq: 4,restricted: true
  end

  down do
    drop_program_function 'Device settings', functional_area: 'RMD', program: 'Utilities'
    drop_program_function 'Setup Device', functional_area: 'RMD', program: 'Utilities'
  end
end
