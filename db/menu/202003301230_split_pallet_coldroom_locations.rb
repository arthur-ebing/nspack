Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'Coldroom Locations', functional_area: 'Lists', program: 'Pallets'
    add_program_function 'All', functional_area: 'Lists', program: 'Pallets', url: '/list/pallet_coldroom_locations', seq: 14, group: 'Coldroom Locations'
    add_program_function 'Stock', functional_area: 'Lists', program: 'Pallets', url: '/list/pallet_coldroom_locations/with_params?key=in_stock&in_stock=true', seq: 15, group: 'Coldroom Locations'
    add_program_function 'Allocated', functional_area: 'Lists', program: 'Pallets', url: '/list/pallet_coldroom_locations/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 16, group: 'Coldroom Locations'
    add_program_function 'Unallocated', functional_area: 'Lists', program: 'Pallets', url: '/list/pallet_coldroom_locations/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 17, group: 'Coldroom Locations'

    add_program_function 'All', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences_coldroom_locations', seq: 18, group: 'Coldroom Locations'
    add_program_function 'Stock', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences_coldroom_locations/with_params?key=in_stock&in_stock=true', seq: 19, group: 'Coldroom Locations'
    add_program_function 'Allocated', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences_coldroom_locations/with_params?key=allocated_stock&in_stock=true&allocated=true', seq: 20, group: 'Coldroom Locations'
    add_program_function 'Unallocated', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/pallet_sequences_coldroom_locations/with_params?key=unallocated_stock&in_stock=true&allocated=false', seq: 21, group: 'Coldroom Locations'
  end

  down do
    add_program_function 'Coldroom Locations', functional_area: 'Lists', program: 'Pallets', url: '/list/pallet_coldroom_locations', seq: 14
    drop_program_function 'All', functional_area: 'Lists', program: 'Pallets', match_group: 'Coldroom Locations'
    drop_program_function 'Stock', functional_area: 'Lists', program: 'Pallets', match_group: 'Coldroom Locations'
    drop_program_function 'Allocated', functional_area: 'Lists', program: 'Pallets', match_group: 'Coldroom Locations'
    drop_program_function 'Unallocated', functional_area: 'Lists', program: 'Pallets', match_group: 'Coldroom Locations'

    drop_program_function 'All', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'Coldroom Locations'
    drop_program_function 'Stock', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'Coldroom Locations'
    drop_program_function 'Allocated', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'Coldroom Locations'
    drop_program_function 'Unallocated', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'Coldroom Locations'
  end
end