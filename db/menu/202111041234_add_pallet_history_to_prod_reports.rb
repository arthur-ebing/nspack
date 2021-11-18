Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Pallet history', functional_area: 'Production', program: 'Reports', url: '/production/reports/pallet_history/pallet', seq: 4
  end

  down do
    drop_program_function 'Pallet history', functional_area: 'Production', program: 'Reports'
  end
end
