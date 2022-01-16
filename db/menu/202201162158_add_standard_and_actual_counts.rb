Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Setup Std and actual counts', functional_area: 'Masterfiles', program: 'Fruit', url: '/masterfiles/fruit/setup_standard_and_actual_counts', seq: 13, group: 'Sizes'
  end

  down do
    drop_program_function 'Setup Std and actual counts', functional_area: 'Masterfiles', program: 'Fruit', match_group: 'Sizes'
  end
end
