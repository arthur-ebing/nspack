Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Pallet Verification', functional_area: 'RMD', program: 'Production', url: '/rmd/production/pallet_verification/scan_pallet_or_carton'
  end

  down do
    drop_program_function 'Pallet Verification', functional_area: 'RMD', program: 'Production'
  end
end
