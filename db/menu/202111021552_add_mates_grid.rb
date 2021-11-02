Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Mates', functional_area: 'Lists', program: 'Pallet Sequences', url: '/list/mates', seq: 22
  end

  down do
    drop_program_function 'Mates', functional_area: 'Lists', program: 'Pallet Sequences'
  end
end
