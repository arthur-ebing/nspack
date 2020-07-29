Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Pallet Verification', functional_area: 'RMD'
    add_program_function 'Pallet Verification', functional_area: 'RMD', program: 'Pallet Verification', url: '/rmd/production/pallet_verification/scan_pallet_or_carton'
    add_program_function 'Pallet Enquiry', functional_area: 'RMD', program: 'Pallet Verification', url: '/rmd/production/pallet_inquiry/scan_pallet', seq: 2
    add_program_function 'Reprint Pallet Label', functional_area: 'RMD', program: 'Pallet Verification', url: '/rmd/production/reprint_pallet_label', seq: 3
  end

  down do
    drop_program 'Pallet Verification', functional_area: 'RMD'
  end
end
