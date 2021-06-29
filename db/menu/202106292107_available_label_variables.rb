Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Available label variables', functional_area: 'Label Designer', program: 'Designs', url: '/labels/labels/labels/view_variables', seq: 7, restricted: true
  end

  down do
    drop_program_function 'Available label variables', functional_area: 'Label Designer', program: 'Designs'
  end
end
