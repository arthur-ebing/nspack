Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Palletizing Bay States', functional_area: 'Production', program: 'Runs', url: '/list/palletizing_bay_states', seq: 7
  end

  down do
    drop_program_function 'Palletizing Bay States', functional_area: 'Production', program: 'Runs'
  end
end
