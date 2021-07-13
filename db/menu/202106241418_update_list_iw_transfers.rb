Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'List', functional_area: 'Finished Goods', program: 'IW Transfers', url: '/finished_goods/inspection/govt_inspection_sheets/list_intake_tripsheets'
  end

  down do
    change_program_function 'List', functional_area: 'Finished Goods', program: 'IW Transfers', url: '/list/vehicle_jobs'
  end
end