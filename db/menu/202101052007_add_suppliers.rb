Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Supplier Groups', functional_area: 'Masterfiles', program: 'Parties', group: 'Suppliers', url: '/list/supplier_groups', seq: 6
    add_program_function 'Suppliers', functional_area: 'Masterfiles', program: 'Parties', group: 'Suppliers', url: '/list/suppliers', seq: 7
  end

  down do
    drop_program_function 'Suppliers', functional_area: 'Masterfiles', program: 'Parties', match_group: 'Suppliers'
    drop_program_function 'Supplier Groups', functional_area: 'Masterfiles', program: 'Parties', match_group: 'Suppliers'
  end
end