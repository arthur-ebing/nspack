Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Failed OTMC Pallets', functional_area: 'Quality', program: 'Test Results', url: '/list/orchard_test_failed_pallets', seq: 4
  end

  down do
    change_program_function 'Failed OTMC Pallets', functional_area: 'Quality', program: 'Test Results', url: '/list/stock_pallets/with_params?key=failed_otmc&failed_otmc=true', seq: 4
  end
end
