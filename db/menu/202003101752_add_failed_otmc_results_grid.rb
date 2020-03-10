Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Failed OTMC Pallets', functional_area: 'Quality', program: 'Test Results', url: '/list/stock_pallets/with_params?key=failed_otmc&failed_otmc=true', seq: 4
  end

  down do
    drop_program_function 'Failed OTMC Pallets', functional_area: 'Quality', program: 'Test Results'
  end
end
