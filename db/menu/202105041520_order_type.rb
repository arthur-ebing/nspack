Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Order Types', functional_area: 'Masterfiles', program: 'Finance', url: '/list/order_types', seq: 7
  end

  down do
    drop_program_function 'Order Types', functional_area: 'Masterfiles', program: 'Finance'
  end
end