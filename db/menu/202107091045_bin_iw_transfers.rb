Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'IW Transfers', functional_area: 'Raw Materials'
    add_program_function 'List', functional_area: 'Raw Materials', program: 'IW Transfers', url: '/raw_materials/deliveries/bins_tripsheets', seq: 1
  end

  down do
    drop_program 'IW Transfers', functional_area: 'Raw Materials'
    drop_program_function 'List', functional_area: 'Raw Materials', program: 'IW Transfers'
  end
end
