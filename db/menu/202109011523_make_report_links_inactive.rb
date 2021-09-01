Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Palletizers', functional_area: 'Production', program: 'Shifts', match_group: 'Summary Reports', hide_if_const_false: 'CR_PROD.incentive_palletizing'
  end

  down do
    change_program_function 'Palletizers', functional_area: 'Production', program: 'Shifts', match_group: 'Summary Reports', hide_if_const_false: nil
  end
end
