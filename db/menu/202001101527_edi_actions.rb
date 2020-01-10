Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Actions', functional_area: 'EDI'
    add_program_function 'Send PS', functional_area: 'EDI', program: 'Actions', url: '/edi/actions/send_ps'
  end

  down do
    drop_program 'Actions', functional_area: 'EDI'
  end
end
