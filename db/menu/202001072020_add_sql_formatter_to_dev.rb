Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'SQL Formatter', functional_area: 'Development', program: 'Generators', url: 'http://sqlformat.darold.net/', seq: 3, show_in_iframe: true
  end

  down do
    drop_program_function 'SQL Formatter', functional_area: 'Development', program: 'Generators'
  end
end

