Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Packing Specifications', functional_area: 'Production', seq: 1
    add_program_function 'List Packing Specifications', functional_area: 'Production', program: 'Packing Specifications', url: '/list/packing_specifications', seq: 1
    add_program_function 'List Packing Specification Items', functional_area: 'Production', program: 'Packing Specifications', url: '/list/packing_specification_items', seq: 2
  end

  down do
    drop_program 'Packing Specifications', functional_area: 'Production'
  end
end