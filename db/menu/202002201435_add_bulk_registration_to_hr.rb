Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Bulk Registration', functional_area: 'Masterfiles', program: 'HR', url: '/list/modules_for_bulk_registration', seq: 9
    add_program_function 'Personnel Identifiers', functional_area: 'Masterfiles', program: 'HR', url: '/list/personnel_identifiers', seq: 10
  end

  down do
    drop_program_function 'Bulk Registration', functional_area: 'Masterfiles', program: 'HR'
    drop_program_function 'Personnel Identifiers', functional_area: 'Masterfiles', program: 'HR'
  end
end
