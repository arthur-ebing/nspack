Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Edit Pallet', rename: 'Edit Pallet By Carton', functional_area: 'RMD', match_group: 'Palletizing', program: 'Production', url: '/rmd/production/palletizing/edit_pallet_by_carton', seq: 3
  end

  down do
    change_program_function 'Edit Pallet By Carton', rename: 'Edit Pallet', functional_area: 'RMD', match_group: 'Palletizing', program: 'Production', url: '/rmd/production/palletizing/edit_pallet', seq: 3
  end
end
