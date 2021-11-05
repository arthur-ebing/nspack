Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'WIP Pallets', functional_area: 'Lists', program: 'Pallets', url: '/list/wip_pallets', seq: 20
  end

  down do
    drop_program_function 'WIP Pallets', functional_area: 'Lists', program: 'Pallets'
  end
end
