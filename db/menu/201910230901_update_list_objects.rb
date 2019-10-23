Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=daily_pack&in_stock=false', seq: 3
    change_program_function 'Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=in_stock&in_stock=true', seq: 4
    change_program_function 'Allocated Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/fg_pallets/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 5
    change_program_function 'Unallocated Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 6
    change_program_function 'Shipped', functional_area: 'Lists', program: 'Pallets', url: '/list/fg_pallets/with_params?key=shipped&shipped=true', seq: 7
    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=scrapped&scrapped=true', seq: 8
    change_program_function 'Failed Inspections', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', seq: 9
    change_program_function 'Failed Verifications', functional_area: 'Lists', program: 'Pallets', url: '/list/stock_pallets/with_params?key=failed_verifications&pallet_verification_failed=true', seq: 10

    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=daily_pack&in_stock=false', seq: 3
    change_program_function 'Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=in_stock&in_stock=true', seq: 4
    change_program_function 'Allocated Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/fg_pallet_sequences/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 5
    change_program_function 'Unallocated Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 6
    change_program_function 'Shipped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/fg_pallet_sequences/with_params?key=shipped&shipped=true', seq: 7
    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=scrapped&scrapped=true', seq: 8
    change_program_function 'Failed Inspections', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', seq: 9
    change_program_function 'Failed Verifications', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/stock_pallet_sequences/with_params?key=failed_verifications&verified=true&verification_passed=false&in_stock=true', seq: 10
  end

  down do
    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=daily_pack&in_stock=false', seq: 3
    change_program_function 'Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=in_stock&in_stock=true', seq: 4
    change_program_function 'Allocated Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 5
    change_program_function 'Unallocated Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 6
    change_program_function 'Shipped', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=shipped&shipped=true', seq: 7
    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=scrapped&scrapped=true', seq: 8
    change_program_function 'Failed Inspections', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', seq: 9
    change_program_function 'Failed Verifications', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=failed_verifications&pallet_verification_failed=true', seq: 10

    change_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=daily_pack&in_stock=false', seq: 3
    change_program_function 'Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=in_stock&in_stock=true', seq: 4
    change_program_function 'Allocated Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 5
    change_program_function 'Unallocated Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 6
    change_program_function 'Shipped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=shipped&shipped=true', seq: 7
    change_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=scrapped&scrapped=true', seq: 8
    change_program_function 'Failed Inspections', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', seq: 9
    change_program_function 'Failed Verifications', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=failed_verifications&verified=true&verification_passed=false&in_stock=true', seq: 10
  end
end
