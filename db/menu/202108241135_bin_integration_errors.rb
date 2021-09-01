Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Bin Integration Errors', functional_area: 'Raw Materials', seq: 1
    add_program_function 'List', functional_area: 'Raw Materials', program: 'Bin Integration Errors', url: '/list/bin_integration_queue/multi?key=standard', seq: 2
  end

  down do
    drop_program 'Bin Integration Errors', functional_area: 'Raw Materials'
  end
end
