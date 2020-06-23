Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'System Resources', functional_area: 'Production', program: 'Resources', url: '/list/system_resources', seq: 4, restricted: true
  end

  down do
    drop_program_function 'System Resources', functional_area: 'Production', program: 'Resources'
  end
end
