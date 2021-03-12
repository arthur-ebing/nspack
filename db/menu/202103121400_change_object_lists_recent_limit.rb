Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Recent', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins?_limit=1000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Carton Labels', url: '/list/carton_labels?_limit=1000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons?_limit=1000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Pallets', url: '/list/all_pallets?_limit=1000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallet_sequences?_limit=1000', match_group: 'List', seq: 2
  end

  down do
    change_program_function 'Recent', functional_area: 'Lists', program: 'Bins', url: '/list/rmt_bins?_limit=5000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Carton Labels', url: '/list/carton_labels?_limit=5000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Cartons', url: '/list/cartons?_limit=5000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Pallets', url: '/list/all_pallets?_limit=5000', match_group: 'List', seq: 2
    change_program_function 'Recent', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/all_pallet_sequences?_limit=5000', match_group: 'List', seq: 2
  end
end
