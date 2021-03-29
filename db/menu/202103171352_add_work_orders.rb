Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New Work Order', functional_area: 'Production', program: 'Orders', url: '/production/orders/work_orders/new', seq: 4, group: 'Work Orders'
    add_program_function 'Work Order List', functional_area: 'Production', program: 'Orders', url: '/list/work_orders', seq: 5, group: 'Work Orders'
    add_program_function 'List Completed', functional_area: 'Production', program: 'Orders', url: '/production/orders/work_orders/completed_work_orders', seq: 6, group: 'Work Orders'
  end

  down do
    drop_program_function 'New Work Order', functional_area: 'Production', program: 'Orders', match_group: 'Work Orders'
    drop_program_function 'New Work List', functional_area: 'Production', program: 'Orders', match_group: 'Work Orders'
    drop_program_function 'List Completed', functional_area: 'Production', program: 'Orders', match_group: 'Work Orders'
  end
end