Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Available pallet numbers', functional_area: 'Production', program: 'Reports', url: '/production/reports/available_pallet_numbers', seq: 2
  end

  down do
    drop_program_function 'Available pallet numbers', functional_area: 'Production', program: 'Reports'
  end
end
