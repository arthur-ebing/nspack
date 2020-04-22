Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Receipts', functional_area: 'Edi', seq: 3
    add_program_function 'For Today', functional_area: 'Edi', program: 'Receipts', group: 'EDI In Transactions', url: '/list/edi_in_transactions/with_params?key=today', seq: 1
    add_program_function 'Errors', functional_area: 'Edi', program: 'Receipts', group: 'EDI In Transactions', url: '/list/edi_in_transactions/with_params?key=errors', seq: 2
    add_program_function 'Recent', functional_area: 'Edi', program: 'Receipts', group: 'EDI In Transactions', url: '/list/edi_in_transactions?_limit=100', seq: 3
    add_program_function 'All', functional_area: 'Edi', program: 'Receipts', group: 'EDI In Transactions', url: '/list/edi_in_transactions', seq: 4
    add_program_function 'Search EDI In Transactions', functional_area: 'Edi', program: 'Receipts', url: '/search/edi_in_transactions', seq: 5
  end

  down do
    drop_program 'Receipts', functional_area: 'Edi'
  end
end
