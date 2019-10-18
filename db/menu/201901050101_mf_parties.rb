Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Masterfiles'
    add_program 'Parties', functional_area: 'Masterfiles'
    add_program_function 'Addresses', functional_area: 'Masterfiles', program: 'Parties', url: '/list/addresses', group: 'Contact Details'
    add_program_function 'Contact Methods', functional_area: 'Masterfiles', program: 'Parties', url: '/list/contact_methods', group: 'Contact Details', seq: 2
    add_program_function 'Organizations', functional_area: 'Masterfiles', program: 'Parties', url: '/list/organizations', seq: 3
    add_program_function 'People', functional_area: 'Masterfiles', program: 'Parties', url: '/list/people', seq: 4
  end

  down do
    drop_functional_area 'Masterfiles'
  end
end
