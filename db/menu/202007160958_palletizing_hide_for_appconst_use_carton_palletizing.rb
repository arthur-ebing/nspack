Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Create New Pallet', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing', hide_if_const_true: 'USE_CARTON_PALLETIZING'
    change_program_function 'Add Sequence', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing', hide_if_const_true: 'USE_CARTON_PALLETIZING'
    change_program_function 'Edit Pallet', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing', hide_if_const_true: 'USE_CARTON_PALLETIZING'
  end

  down do
    change_program_function 'Create New Pallet', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing', hide_if_const_true: nil
    change_program_function 'Add Sequence', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing', hide_if_const_true: nil
    change_program_function 'Edit Pallet', functional_area: 'RMD', program: 'Production', match_group: 'Palletizing', hide_if_const_true: nil
  end
end
