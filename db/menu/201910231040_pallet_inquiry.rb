Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Production', functional_area: 'RMD'
    add_program_function 'Pallet Enquiry', functional_area: 'RMD', program: 'Production', url: '/rmd/production/pallet_inquiry/scan_pallet'
  end

  down do
    drop_program 'Production', functional_area: 'RMD'
    drop_program_function 'Pallet Enquiry', functional_area: 'RMD', program: 'Production'
  end
end
