Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'IW Transfers', functional_area: 'Finished Goods'
    add_program_function 'List', functional_area: 'Finished Goods', program: 'IW Transfers', url: '/list/vehicle_jobs', seq: 1
  end

  down do
    drop_program 'IW Transfers', functional_area: 'Finished Goods'
    drop_program_function 'List', functional_area: 'Finished Goods', program: 'IW Transfers'
  end
end
