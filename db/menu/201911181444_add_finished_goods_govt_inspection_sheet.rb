Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Inspection', functional_area: 'Finished Goods'
    add_program_function 'Govt Inspection Sheets', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/govt_inspection_sheets', seq: 1
    add_program_function 'Govt Inspection Pallet Api Results', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/govt_inspection_pallet_api_results', seq: 2
    add_program_function 'Govt Inspection Api Results', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/govt_inspection_api_results', seq: 3

    add_program_function 'Inspectors', functional_area: 'Masterfiles', program: 'Quality', url: '/list/inspectors', seq: 10
    add_program_function 'Inspection Failure Reasons', functional_area: 'Masterfiles', program: 'Quality', url: '/list/inspection_failure_reasons', seq: 11
    add_program_function 'Inspection Failure Types', functional_area: 'Masterfiles', program: 'Quality', url: '/list/inspection_failure_types', seq: 12
  end

  down do
    drop_program 'Inspection', functional_area: 'Finished Goods'
    drop_program_function 'Inspectors', functional_area: 'Masterfiles', program: 'Quality'
    drop_program_function 'Inspection Failure Types', functional_area: 'Masterfiles', program: 'Quality'
    drop_program_function 'Inspection Failure Reasons', functional_area: 'Masterfiles', program: 'Quality'
  end
end
