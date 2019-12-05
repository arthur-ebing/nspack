Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Create New Pallet', functional_area: 'RMD', program: 'Production', group: 'Palletizing', url: '/rmd/production/palletizing/create_new_pallet'
    add_program_function 'Add Sequence', functional_area: 'RMD', program: 'Production', group: 'Palletizing', url: '/rmd/production/palletizing/add_sequence_to_pallet'
    add_program_function 'Edit Pallet', functional_area: 'RMD', program: 'Production', group: 'Palletizing', url: '/rmd/production/palletizing/edit_pallet'
  end

  down do
    drop_program_function 'Create New Pallet', functional_area: 'RMD', program: 'Production'
    drop_program_function 'Add Sequence', functional_area: 'RMD', program: 'Production'
    drop_program_function 'Edit Pallet', functional_area: 'RMD', program: 'Production'
  end
end
