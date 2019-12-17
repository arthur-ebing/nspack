Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Reports', functional_area: 'Production'
    add_program_function 'Aggregate Packout', functional_area: 'Production', program: 'Reports', url: '/production/reports/aggregate_packout', seq: 1
  end

  down do
    drop_program 'Reports', functional_area: 'Production'
  end
end
