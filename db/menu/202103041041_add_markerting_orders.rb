Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Orders', functional_area: 'Production', seq: 1
    add_program_function 'New Marketing Order', functional_area: 'Production', program: 'Orders', url: '/production/orders/marketing_orders/new', seq: 1, group: 'Marketing Orders'
    add_program_function 'Marketing Order List', functional_area: 'Production', program: 'Orders', url: '/list/marketing_orders', seq: 2, group: 'Marketing Orders'
    add_program_function 'List Completed', functional_area: 'Production', program: 'Orders', url: '/production/orders/marketing_orders/completed_marketing_orders', seq: 3, group: 'Marketing Orders'
  end

  down do
    drop_program 'Orders', functional_area: 'Production'
  end
end