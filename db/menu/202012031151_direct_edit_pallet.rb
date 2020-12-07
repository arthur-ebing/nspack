Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Edit Pallet', functional_area: 'RMD', program: 'Production', group: 'Palletizing', url: '/rmd/production/palletizing/direct_edit_pallet', seq: 5
  end

  down do
    drop_program_function 'Edit Pallet', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing'
  end
end