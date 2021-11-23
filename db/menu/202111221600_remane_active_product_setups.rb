Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Active Product Setups',
                            functional_area: 'Production',
                            program: 'Product Setups',
                            rename: 'Available Product Setups'

    change_program_function 'Active Packing Specifications',
                            functional_area: 'Production',
                            program: 'Packing Specifications',
                            rename: 'Available Packing Specifications'
  end

  down do
    change_program_function 'Available Product Setups',
                            functional_area: 'Production',
                            program: 'Product Setups',
                            rename: 'Active Product Setups'

    change_program_function 'Available Packing Specifications',
                            functional_area: 'Production',
                            program: 'Packing Specifications',
                            rename: 'Active Packing Specifications'
  end
end
