Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Set Temp Tail', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/temp_tail', seq: 4
  end

  down do
    drop_program_function 'Set Temp Tail', functional_area: 'RMD', program: 'Dispatch'
  end
end
