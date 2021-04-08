Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Packing Specification Templates',
                         functional_area: 'Production',
                         program: 'Packing Specifications',
                         url: '/list/packing_specification_templates/with_params?key=active&product_setup_templates.active=true',
                         seq: 1
    add_program_function 'Active Packing Specifications',
                         functional_area: 'Production',
                         program: 'Packing Specifications',
                         url: '/list/packing_specification_details/with_params?key=active&active=true',
                         seq: 2
    add_program_function 'Packing Specifications in Production',
                         functional_area: 'Production',
                         program: 'Packing Specifications',
                         url: '/list/packing_specification_details/with_params?key=in_production&in_production=true',
                         seq: 3
    change_program_function 'List Packing Specification Items',
                            functional_area: 'Production',
                            program: 'Packing Specifications',
                            rename: 'Packing Specification Items',
                            seq: 4
  end

  down do
    drop_program_function 'Packing Specification Templates',
                         functional_area: 'Production',
                         program: 'Packing Specifications'
    drop_program_function 'Active Packing Specifications',
                         functional_area: 'Production',
                         program: 'Packing Specifications'
    drop_program_function 'Packing Specifications in Production',
                         functional_area: 'Production',
                         program: 'Packing Specifications'
    change_program_function 'Packing Specification Items',
                            functional_area: 'Production',
                            program: 'Packing Specifications',
                            rename: 'List Packing Specification Items'
  end
end
