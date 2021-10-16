Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'RMT Customers', functional_area: 'Masterfiles', program: 'Parties', url: '/list/customers/with_params?key=rmt', seq: 9
    change_program_function 'Customers', functional_area: 'Masterfiles', program: 'Parties', url: '/list/customers/with_params?key=standard'
  end

  down do
    drop_program_function 'RMT Customers', functional_area: 'Masterfiles', program: 'Parties'
    change_program_function ' Customers', functional_area: 'Masterfiles', program: 'Parties', url: '/list/customers'
  end
end
