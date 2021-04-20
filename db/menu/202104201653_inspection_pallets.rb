Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Inspection Pallets', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/inspection_pallets', seq: 3
  end

  down do
    drop_program_function 'Inspection Pallets', functional_area: 'Finished Goods', program: 'Inspection'
  end
end