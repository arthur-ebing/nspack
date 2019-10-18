Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Production'
    add_program 'Resources', functional_area: 'Production'
    add_program_function 'Plant Resource Types', functional_area: 'Production', program: 'Resources', url: '/list/plant_resource_types', group: 'Resource Types', seq: 1
    add_program_function 'System Resource Types', functional_area: 'Production', program: 'Resources', url: '/list/system_resource_types', group: 'Resource Types', seq: 2
    add_program_function 'Plant Resources', functional_area: 'Production', program: 'Resources', url: '/list/plant_resources', seq: 3

    add_program 'Product Setups', functional_area: 'Production'
    add_program_function 'Product Setup Templates', functional_area: 'Production', program: 'Product Setups', url: '/list/product_setup_templates/with_params?key=active&product_setup_templates.active=true'
    add_program_function 'Search Product Setup Templates', functional_area: 'Production', program: 'Product Setups', url: '/search/product_setup_templates', seq: 2
    add_program_function 'Active Product Setups', functional_area: 'Production', program: 'Product Setups', url: '/list/product_setup_details/with_params?key=active&product_setups.active=true', seq: 3
    add_program_function 'Product Setups in Production', functional_area: 'Production', program: 'Product Setups', url: '/list/product_setup_details/with_params?key=in_production&in_production=true', seq: 4
    add_program_function 'Search Product Setups', functional_area: 'Production', program: 'Product Setups', url: '/search/product_setups', seq: 5

    add_program 'Runs', functional_area: 'Production'
    add_program_function 'List Production runs', functional_area: 'Production', program: 'Runs', url: '/list/production_runs'
    add_program_function 'Search Production runs', functional_area: 'Production', program: 'Runs', url: '/search/production_runs', seq: 2
    add_program_function 'Cartons', functional_area: 'Production', program: 'Runs', url: '/list/cartons', seq: 3, group: 'List Objects'
    add_program_function 'Cartons', functional_area: 'Production', program: 'Runs', url: '/search/cartons', seq: 4, group: 'Search Objects'
  end

  down do
    drop_functional_area 'Production'
  end
end
