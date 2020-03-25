Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Packing methods', functional_area: 'Masterfiles', program: 'Packaging', url: '/list/packing_methods', seq: 13
  end

  down do
    drop_program_function 'Packing methods', functional_area: 'Masterfiles', program: 'Packaging'
  end
end