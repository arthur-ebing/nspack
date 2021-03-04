Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Finance', functional_area: 'Masterfiles', seq: 1
    add_program_function 'Currencies', functional_area: 'Masterfiles', program: 'Finance', url: '/list/currencies', seq: 1
    add_program_function 'Deal Types', functional_area: 'Masterfiles', program: 'Finance', url: '/list/deal_types', seq: 2
    add_program_function 'Incoterms', functional_area: 'Masterfiles', program: 'Finance', url: '/list/incoterms', seq: 3

    add_program_function 'Payment Term Types', group: 'Payment Terms',  functional_area: 'Masterfiles', program: 'Finance', url: '/list/payment_term_types', seq: 4
    add_program_function 'Payment Terms', group: 'Payment Terms',  functional_area: 'Masterfiles', program: 'Finance', url: '/list/payment_terms', seq: 5
    add_program_function 'Payment Term Date Types', group: 'Payment Terms',  functional_area: 'Masterfiles', program: 'Finance', url: '/list/payment_term_date_types', seq: 6

    add_program_function 'Customers', functional_area: 'Masterfiles', program: 'Parties', url: '/list/customers', seq: 5
  end

  down do
    drop_program_function 'Customers', functional_area: 'Masterfiles', program: 'Parties'
    drop_program 'Finance', functional_area: 'Masterfiles'
  end
end