Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'List', functional_area: 'Lists', program: 'Bins'
    drop_program_function 'List', functional_area: 'Lists', program: 'Cartons'
    drop_program_function 'List', functional_area: 'Lists', program: 'Pallets'
    drop_program_function 'List', functional_area: 'Lists', program: 'Pallet Sequences'

    add_program_function 'Recent', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins?_limit=5000', group: 'List', seq: 2
    add_program_function 'All', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins', group: 'List', seq: 3

    add_program_function 'Recent', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons?_limit=5000', group: 'List', seq: 2
    add_program_function 'All', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons', group: 'List', seq: 3

    add_program_function 'Recent', functional_area: 'Lists', program: 'Pallets', url: '/list/all_pallets?_limit=5000', group: 'List', seq: 2
    add_program_function 'All', functional_area: 'Lists', program: 'Pallets', url: '/list/all_pallets', group: 'List', seq: 3

    add_program_function 'Recent', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallet_sequences?_limit=5000', group: 'List', seq: 2
    add_program_function 'All', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallet_sequences', group: 'List', seq: 3
  end

  down do
    drop_program_function 'Recent', functional_area: 'Lists', program: 'Bins', match_group: 'List'
    drop_program_function 'All', functional_area: 'Lists', program: 'Bins', match_group: 'List'

    drop_program_function 'Recent', functional_area: 'Lists', program: 'Cartons', match_group: 'List'
    drop_program_function 'All', functional_area: 'Lists', program: 'Cartons', match_group: 'List'

    drop_program_function 'Recent', functional_area: 'Lists', program: 'Pallets', match_group: 'List'
    drop_program_function 'All', functional_area: 'Lists', program: 'Pallets', match_group: 'List'

    drop_program_function 'Recent', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'List'
    drop_program_function 'All', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'List'

    add_program_function 'List', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins', seq: 2
    add_program_function 'List', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons', seq: 2
    add_program_function 'List', functional_area: 'Lists', program: 'Pallets', url: '/list/all_pallets', seq: 2
    add_program_function 'List', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallet_sequences', seq: 2
  end
end
