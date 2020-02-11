Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'List: Bin Weight', functional_area: 'Lists', program: 'Bins', group: 'Reworks', url: '/list/reworks_bin_weight', seq: 6
    add_program_function 'Search: Bin Weight', functional_area: 'Lists', program: 'Bins', group: 'Reworks', url: '/search/reworks_bin_weight', seq: 7
  end

  down do
    drop_program_function 'List: Bin Weight', functional_area: 'Lists', program: 'Bins', match_group: 'Reworks'
    drop_program_function 'Search: Bin Weight', functional_area: 'Lists', program: 'Bins', match_group: 'Reworks'
  end
end
