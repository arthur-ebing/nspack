Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'General', functional_area: 'Masterfiles'
    add_program_function 'UOMs', functional_area: 'Masterfiles', program: 'General', url: '/list/uoms'
  end

  down do
    drop_program 'General', functional_area: 'Masterfiles'
  end
end
