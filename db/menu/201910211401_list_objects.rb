Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Lists'
    add_program 'Bins', functional_area: 'Lists'
    add_program_function 'List', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins', seq: 1
    add_program_function 'Search', functional_area: 'Lists', program: 'Bins', url: '/search/rmt_bins', seq: 2
    add_program_function 'Tipped', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins/with_params?key=tipped&tipped=true', seq: 3
    add_program_function 'In Stock', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins/with_params?key=tipped&tipped=false', seq: 4

    add_program 'Cartons', functional_area: 'Lists'
    add_program_function 'List', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons', seq: 1
    add_program_function 'Search', functional_area: 'Lists', program: 'Cartons', url: '/search/cartons', seq: 2

    add_program 'Pallets', functional_area: 'Lists'
    add_program_function 'List', functional_area: 'Lists', program: 'Pallets', url: '/list/all_pallets', seq: 1
    add_program_function 'Search', functional_area: 'Lists', program: 'Pallets', url: '/search/pallets', seq: 2
    add_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=daily_pack&in_stock=false', seq: 3
    add_program_function 'Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=in_stock&in_stock=true', seq: 4
    add_program_function 'Allocated Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 5
    add_program_function 'Unallocated Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 6
    add_program_function 'Shipped', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=shipped&shipped=true', seq: 7
    add_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=scrapped&scrapped=true', seq: 8
    add_program_function 'Failed Inspections', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', seq: 9
    add_program_function 'Failed Verifications', functional_area: 'Lists', program: 'Pallets', url: '/list/pallets/with_params?key=failed_verifications&pallet_verification_failed=true', seq: 10

    add_program 'Pallet Sequences', functional_area: 'Lists'
    add_program_function 'List', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallets', seq: 1
    add_program_function 'Search', functional_area: 'Lists', program: 'Pallet Sequences', url: '/search/pallets', seq: 2
    add_program_function 'Daily Pack', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=daily_pack&in_stock=false', seq: 3
    add_program_function 'Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=in_stock&in_stock=true', seq: 4
    add_program_function 'Allocated Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 5
    add_program_function 'Unallocated Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 6
    add_program_function 'Shipped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=shipped&shipped=true', seq: 7
    add_program_function 'Scrapped', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=scrapped&scrapped=true', seq: 8
    add_program_function 'Failed Inspections', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=failed_inspections&inspected=true&govt_inspection_passed=false', seq: 9
    add_program_function 'Failed Verifications', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences/with_params?key=failed_verifications&verified=true&verification_passed=false&in_stock=true', seq: 10
  end

  down do
    drop_functional_area 'Lists'
  end
end
