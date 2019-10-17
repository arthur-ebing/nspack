Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Quality', functional_area: 'Masterfiles'
    add_program_function 'Pallet Verification Failure Reasons', functional_area: 'Masterfiles', program: 'Quality', url: '/list/pallet_verification_failure_reasons'
  end

  down do
    drop_program 'Quality', functional_area: 'Masterfiles'
  end
end
