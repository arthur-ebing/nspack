Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'All - Sequences', functional_area: 'Lists', program: 'Pallet Sequences', group: 'List', url: '/list/pallet_sequences_view', seq: 3
  end

  down do
    drop_program_function 'All - Sequences', functional_area: 'Lists', program: 'Pallet Sequences', match_group: 'List'
  end
end

