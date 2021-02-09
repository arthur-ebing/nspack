Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Inspections', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/inspections', seq: 2
  end

  down do
    drop_program_function 'Inspections', functional_area: 'Finished Goods', program: 'Inspection'
  end
end