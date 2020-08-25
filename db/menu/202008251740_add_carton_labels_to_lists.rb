Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Carton Labels', functional_area: 'Lists'
    add_program_function 'Recent', functional_area: 'Lists', program: 'Carton Labels', url: '/list/carton_labels?_limit=5000', group: 'List', seq: 2
    add_program_function 'All', functional_area: 'Lists', program: 'Carton Labels', url: '/list/carton_labels', group: 'List', seq: 3
    add_program_function 'Search', functional_area: 'Lists', program: 'Carton Labels', url: '/search/carton_labels', seq: 2
  end

  down do
    drop_program_function 'Recent', functional_area: 'Lists', program: 'Carton Labels', match_group: 'List'
    drop_program_function 'All', functional_area: 'Lists', program: 'Carton Labels', match_group: 'List'
    drop_program_function 'Search', functional_area: 'Lists', program: 'Carton Labels'
    drop_program 'Carton Labels', functional_area: 'Lists'
  end
end
