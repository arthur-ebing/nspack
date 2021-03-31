Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'List Packing Specifications', functional_area: 'Production', program: 'Packing Specifications'
  end

  down do
    add_program_function 'List Packing Specifications', functional_area: 'Production', program: 'Packing Specifications', url: '/list/packing_specifications', seq: 1
  end
end