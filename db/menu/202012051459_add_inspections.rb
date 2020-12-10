Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Inspection Types', functional_area: 'Masterfiles', program: 'Quality', url: '/list/inspection_types', seq: 13
  end

  down do
    drop_program_function 'Inspection Types', functional_area: 'Masterfiles', program: 'Quality'
  end
end