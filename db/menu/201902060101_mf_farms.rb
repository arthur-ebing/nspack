Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Farms', functional_area: 'Masterfiles'
    add_program_function 'Production Regions', functional_area: 'Masterfiles', program: 'Farms', url: '/list/production_regions'
    add_program_function 'Pucs', functional_area: 'Masterfiles', program: 'Farms', url: '/list/pucs', seq: 2
    add_program_function 'Farm Groups', functional_area: 'Masterfiles', program: 'Farms', url: '/list/farm_groups', seq: 3
    add_program_function 'Farms', functional_area: 'Masterfiles', program: 'Farms', url: '/list/farms', seq: 4
    add_program_function 'Orchards', functional_area: 'Masterfiles', program: 'Farms', url: '/list/orchard_details', seq: 5
    add_program_function 'Rmt Container Types', functional_area: 'Masterfiles', program: 'Farms', url: '/list/rmt_container_types', seq: 6
    add_program_function 'Rmt Container Material Types', functional_area: 'Masterfiles', program: 'Farms', url: '/list/rmt_container_material_types', seq: 7
  end

  down do
    drop_program 'Farms', functional_area: 'Masterfiles'
  end
end
