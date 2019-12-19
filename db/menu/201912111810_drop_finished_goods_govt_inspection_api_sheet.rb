Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'Govt Inspection Api Results', functional_area: 'Finished Goods', program: 'Inspection'
    drop_program_function 'Govt Inspection Pallet Api Results', functional_area: 'Finished Goods', program: 'Inspection'
  end

  down do
    add_program_function 'Govt Inspection Pallet Api Results', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/govt_inspection_pallet_api_results', seq: 2
    add_program_function 'Govt Inspection Api Results', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/govt_inspection_api_results', seq: 3
  end
end
