Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'All - Grouped Sequences', functional_area: 'Lists', program: 'Pallets', group: 'List', url: '/list/pallets_view', seq: 3
  end

  down do
    drop_program_function 'All - Grouped Sequences', functional_area: 'Lists', program: 'Pallets', match_group: 'List'
  end
end

