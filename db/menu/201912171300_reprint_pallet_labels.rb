Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Reprint Pallet Label', functional_area: 'RMD', program: 'Production', group: 'Palletizing', url: '/rmd/production/reprint_pallet_label', seq: 4
  end

  down do
    drop_program_function 'Reprint Pallet Label', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing'
  end
end
