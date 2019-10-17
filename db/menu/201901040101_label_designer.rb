Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'Label Designer'
    add_program 'Designs', functional_area: 'Label Designer'
    add_program_function 'List Labels', functional_area: 'Label Designer', program: 'Designs', url: '/list/labels/with_params?key=active'
    add_program_function 'New label', functional_area: 'Label Designer', program: 'Designs', url: '/labels/labels/labels/new', seq: 2
    add_program_function 'Available printers', functional_area: 'Label Designer', program: 'Designs', url: '/list/printers', seq: 3
    add_program_function 'Printer applications', functional_area: 'Label Designer', program: 'Designs', url: '/list/printer_applications', seq: 4
    add_program_function 'Archived labels', functional_area: 'Label Designer', program: 'Designs', url: '/list/labels/with_params?key=inactive', seq: 5
    add_program_function 'Import label', functional_area: 'Label Designer', program: 'Designs', url: '/labels/labels/labels/import', seq: 6, restricted: true

    add_program 'Master Lists', functional_area: 'Label Designer'
    add_program_function 'Label Types', functional_area: 'Label Designer', program: 'Master Lists', url: '/list/master_lists/with_params?key=label_type'

    add_program 'Publish', functional_area: 'Label Designer'
    add_program_function 'Select and publish', functional_area: 'Label Designer', program: 'Publish', url: '/labels/publish/batch'
  end

  down do
    drop_functional_area 'Label Designer'
  end
end
