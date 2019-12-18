Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Reprint Pallet Label', functional_area: 'RMD', program: 'Production', url: '/rmd/production/reprint_pallet_label', seq: 1
  end

  down do
    drop_program_function 'Reprint Pallet Label', functional_area: 'RMD', program: 'Production'
  end
end
