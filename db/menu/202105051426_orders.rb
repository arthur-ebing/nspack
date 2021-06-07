Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Orders', functional_area: 'Finished Goods', seq: 1
    add_program_function 'Orders', functional_area: 'Finished Goods', program: 'Orders', url: '/list/orders', seq: 1

    change_program_function 'Order Types', functional_area: 'Masterfiles', program: 'Finance', seq: 4

    change_program_function 'Payment Term Types', match_group: 'Payment Terms',  functional_area: 'Masterfiles', program: 'Finance', seq: 5
    change_program_function 'Payment Term Date Types', match_group: 'Payment Terms',  functional_area: 'Masterfiles', program: 'Finance', seq: 6
    change_program_function 'Payment Terms', match_group: 'Payment Terms',  functional_area: 'Masterfiles', program: 'Finance', seq: 7
    add_program_function 'Payment Term Sets', group: 'Payment Terms', functional_area: 'Masterfiles', program: 'Finance', url: '/list/customer_payment_term_sets', seq: 8
  end

  down do
    drop_program_function 'Payment Term Sets', match_group: 'Payment Terms', functional_area: 'Masterfiles', program: 'Finance'
    drop_program 'Orders', functional_area: 'Finished Goods'
  end
end