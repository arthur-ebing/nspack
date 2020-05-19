Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    move_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Dispatch', to_program: 'Finished Goods'
    move_program_function 'Truck Arrival', functional_area: 'RMD', program: 'Dispatch', to_program: 'Finished Goods'
    move_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', to_program: 'Finished Goods'
    move_program_function 'Set Temp Tail', functional_area: 'RMD', program: 'Dispatch', to_program: 'Finished Goods'

    change_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Finished Goods', group: 'Dispatch', url: '/rmd/finished_goods/dispatch/allocate/load', seq: 1
    change_program_function 'Truck Arrival', functional_area: 'RMD', program: 'Finished Goods', group: 'Dispatch', url: '/rmd/finished_goods/dispatch/truck_arrival/load', seq: 2
    change_program_function 'Load Truck', functional_area: 'RMD', program: 'Finished Goods', group: 'Dispatch', url: '/rmd/finished_goods/dispatch/load_truck/load', seq: 3
    change_program_function 'Set Temp Tail', functional_area: 'RMD', program: 'Finished Goods', group: 'Dispatch', url: '/rmd/finished_goods/dispatch/temp_tail', seq: 4

    drop_program 'Dispatch', functional_area: 'RMD'
  end

  down do
    add_program 'Dispatch', functional_area: 'RMD', seq: 4

    move_program_function 'Allocate Pallets', functional_area: 'RMD', to_program: 'Dispatch', program: 'Finished Goods'
    move_program_function 'Truck Arrival', functional_area: 'RMD', to_program: 'Dispatch', program: 'Finished Goods'
    move_program_function 'Load Truck', functional_area: 'RMD', to_program: 'Dispatch', program: 'Finished Goods'
    move_program_function 'Set Temp Tail', functional_area: 'RMD', to_program: 'Dispatch', program: 'Finished Goods'

    change_program_function 'Allocate Pallets', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/allocate/load', seq: 1
    change_program_function 'Truck Arrival', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/truck_arrival/load', seq: 2
    change_program_function 'Load Truck', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/load_truck/load', seq: 3
    change_program_function 'Set Temp Tail', functional_area: 'RMD', program: 'Dispatch', url: '/rmd/dispatch/temp_tail', seq: 4
  end
end
